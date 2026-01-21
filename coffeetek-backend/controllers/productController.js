const db = require('../config/db');

exports.getProducts = async (req, res) => {
    try {
        const query = `
            SELECT 
                p.product_id, 
                p.product_name, 
                p.category_id, 
                c.category_name,
                c.image_url as category_image,
                c.grid_column_count,
                p.description, 
                p.image_url, 
                p.is_active,
                pr.price_value,
                (
                    EXISTS (SELECT 1 FROM product_modifier_links pml WHERE pml.product_id = p.product_id) 
                    OR 
                    EXISTS (SELECT 1 FROM category_modifier_links cml WHERE cml.category_id = p.category_id)
                ) as has_modifiers
            FROM products p
            JOIN categories c ON p.category_id = c.category_id
            LEFT JOIN product_prices pr ON p.product_id = pr.product_id
            WHERE 
                p.is_active = 1 
                AND (pr.end_date IS NULL OR pr.end_date > NOW())
            ORDER BY p.category_id ASC;
        `;
        
        const [rows] = await db.query(query);

        const products = rows.map(row => ({
            product_id: row.product_id.toString(),
            product_name: row.product_name,
            category_id: row.category_id.toString(),
            category_name: row.category_name,
            category_image: row.category_image,
            grid_column_count: row.grid_column_count || 4,
            description: row.description,
            image_url: row.image_url,
            is_active: row.is_active,
            price_value: parseFloat(row.price_value) || 0,
            has_modifiers: row.has_modifiers === 1
        }));

        res.status(200).json(products);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Lỗi server khi lấy danh sách sản phẩm' });
    }
};

// [FIX] Lấy danh sách Modifier cụ thể của từng món (Đọc từ bảng product_modifiers)
exports.getProductModifiers = async (req, res) => {
    try {
        const productId = req.params.id;

        // Query: Lấy Modifier từ bảng product_modifiers (nơi chúng ta vừa lưu)
        // Join sang modifiers và modifier_groups để lấy thông tin chi tiết
        const query = `
            SELECT 
                m.modifier_id, 
                m.modifier_name, 
                m.extra_price,
                m.is_input_required, -- [QUAN TRỌNG] Cờ cho phép nhập
                mg.group_id, 
                mg.group_name, 
                mg.is_multi_select, 
                mg.is_required
            FROM product_modifiers pm
            JOIN modifiers m ON pm.modifier_id = m.modifier_id
            JOIN modifier_groups mg ON m.group_id = mg.group_id
            WHERE pm.product_id = ?
            ORDER BY mg.group_id, m.modifier_id;
        `;

        const [rows] = await db.query(query, [productId]);

        // Nếu không có modifier riêng, có thể fallback về Category nếu bạn muốn (tùy logic cũ)
        // Nhưng theo logic "Product-based" thì ta chỉ cần đoạn trên là đủ.

        // Biến đổi dữ liệu phẳng (Flat) thành dạng Cây (Nested)
        const groupsMap = new Map();

        rows.forEach(row => {
            const groupId = row.group_id.toString();
            
            if (!groupsMap.has(groupId)) {
                groupsMap.set(groupId, {
                    group_id: groupId,
                    group_name: row.group_name,
                    is_multi_select: row.is_multi_select === 1,
                    is_required: row.is_required === 1,
                    modifiers: []
                });
            }
            
            groupsMap.get(groupId).modifiers.push({
                modifier_id: row.modifier_id.toString(),
                modifier_name: row.modifier_name,
                extra_price: parseFloat(row.extra_price),
                // [QUAN TRỌNG] Map cờ này để App hiển thị ô nhập
                is_input_required: (
                    row.is_input_required === 1 || 
                    row.is_input_required === true || 
                    (Buffer.isBuffer(row.is_input_required) && row.is_input_required[0] === 1)
                ),
                group_id: groupId
            });
        });

        const result = Array.from(groupsMap.values());
        res.status(200).json(result);

    } catch (error) {
        console.error("Lỗi lấy modifier:", error);
        res.status(500).json({ message: 'Lỗi server khi lấy modifier' });
    }
};

exports.createProduct = async (req, res) => {
    const connection = await db.getConnection();
    try {
        await connection.beginTransaction();
        
        // Nhận thêm modifier_ids từ body (là mảng các id: [1, 2, 5])
        const { product_name, category_id, description, image_url, price, modifier_ids } = req.body;

        // 1. Insert Product
        const [resProd] = await connection.query(
            "INSERT INTO products (product_name, category_id, description, image_url, is_active) VALUES (?, ?, ?, ?, 1)",
            [product_name, category_id, description, image_url]
        );
        const newProductId = resProd.insertId;

        // 2. Insert Price
        await connection.query(
            "INSERT INTO product_prices (product_id, price_value, effective_date) VALUES (?, ?, NOW())",
            [newProductId, price]
        );

        // 3. [MỚI] Insert Modifiers (Nếu có)
        if (modifier_ids && Array.isArray(modifier_ids) && modifier_ids.length > 0) {
            const values = modifier_ids.map(modId => [newProductId, modId]);
            await connection.query(
                "INSERT INTO product_modifiers (product_id, modifier_id) VALUES ?",
                [values]
            );
        }

        await connection.commit();
        res.status(201).json({ message: 'Thêm món thành công', product_id: newProductId });

    } catch (error) {
        await connection.rollback();
        console.error(error);
        res.status(500).json({ message: 'Lỗi thêm món' });
    } finally {
        connection.release();
    }
};

// [THÊM MỚI] 2. Cập nhật sản phẩm
exports.updateProduct = async (req, res) => {
    const connection = await db.getConnection();
    try {
        await connection.beginTransaction();
        const productId = req.params.id;
        // Nhận thêm modifier_ids
        const { product_name, category_id, description, image_url, price, modifier_ids } = req.body;

        // 1. Update Product Info
        await connection.query(
            "UPDATE products SET product_name = ?, category_id = ?, description = ?, image_url = ? WHERE product_id = ?",
            [product_name, category_id, description, image_url, productId]
        );

        // 2. Update Price
        await connection.query(
            "UPDATE product_prices SET price_value = ? WHERE product_id = ? AND (end_date IS NULL OR end_date > NOW())",
            [price, productId]
        );

        // 3. [MỚI] Update Modifiers
        // Chiến thuật: Xóa hết cái cũ -> Thêm lại cái mới (đơn giản và hiệu quả)
        if (modifier_ids && Array.isArray(modifier_ids)) {
            // Xóa cũ
            await connection.query("DELETE FROM product_modifiers WHERE product_id = ?", [productId]);
            
            // Thêm mới (nếu mảng không rỗng)
            if (modifier_ids.length > 0) {
                const values = modifier_ids.map(modId => [productId, modId]);
                await connection.query(
                    "INSERT INTO product_modifiers (product_id, modifier_id) VALUES ?",
                    [values]
                );
            }
        }

        await connection.commit();
        res.status(200).json({ message: 'Cập nhật món thành công' });

    } catch (error) {
        await connection.rollback();
        console.error(error);
        res.status(500).json({ message: 'Lỗi cập nhật món' });
    } finally {
        connection.release();
    }
};

// [THÊM MỚI] 3. Đổi trạng thái (Ẩn/Hiện món)
exports.toggleProductStatus = async (req, res) => {
    try {
        const productId = req.params.id;
        const { is_active } = req.body; // true/false

        await db.query("UPDATE products SET is_active = ? WHERE product_id = ?", [is_active ? 1 : 0, productId]);
        res.status(200).json({ message: 'Đã đổi trạng thái món' });
    } catch (error) {
        res.status(500).json({ message: 'Lỗi đổi trạng thái' });
    }
};

exports.getProductModifierIds = async (req, res) => {
    try {
        const productId = req.params.id;
        const [rows] = await db.query(
            "SELECT modifier_id FROM product_modifiers WHERE product_id = ?", 
            [productId]
        );
        // Trả về mảng ID đơn giản: [1, 5, 10]
        const ids = rows.map(row => row.modifier_id.toString());
        res.status(200).json(ids);
    } catch (error) {
        res.status(500).json({ message: 'Lỗi lấy danh sách ID modifier' });
    }
};