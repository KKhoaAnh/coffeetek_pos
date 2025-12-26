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

exports.getProductModifiers = async (req, res) => {
    try {
        const productId = req.params.id;

        const [prodRows] = await db.query('SELECT category_id FROM products WHERE product_id = ?', [productId]);
        if (prodRows.length === 0) return res.status(404).json({ message: 'Sản phẩm không tồn tại' });
        const categoryId = prodRows[0].category_id;

        const query = `
            SELECT 
                mg.group_id, 
                mg.group_name, 
                mg.is_multi_select, 
                mg.is_required,
                m.modifier_id, 
                m.modifier_name, 
                m.extra_price
            FROM modifier_groups mg
            JOIN modifiers m ON mg.group_id = m.group_id
            WHERE 
                mg.group_id IN (SELECT group_id FROM product_modifier_links WHERE product_id = ?)
                OR 
                mg.group_id IN (SELECT group_id FROM category_modifier_links WHERE category_id = ?)
            ORDER BY mg.group_id, m.modifier_id;
        `;

        const [rows] = await db.query(query, [productId, categoryId]);

        const groupsMap = new Map();

        rows.forEach(row => {
            if (!groupsMap.has(row.group_id)) {
                groupsMap.set(row.group_id, {
                    group_id: row.group_id.toString(),
                    group_name: row.group_name,
                    is_multi_select: row.is_multi_select === 1,
                    is_required: row.is_required === 1,
                    modifiers: []
                });
            }
            groupsMap.get(row.group_id).modifiers.push({
                modifier_id: row.modifier_id.toString(),
                modifier_name: row.modifier_name,
                extra_price: parseFloat(row.extra_price)
            });
        });

        const result = Array.from(groupsMap.values());
        res.status(200).json(result);

    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Lỗi server khi lấy modifier' });
    }
};