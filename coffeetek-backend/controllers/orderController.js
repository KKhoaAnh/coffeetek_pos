const db = require('../config/db');

exports.createOrder = async (req, res) => {
    const connection = await db.getConnection();
    
    try {
        await connection.beginTransaction();

        const orderData = req.body;

        const [orderResult] = await connection.query(
            `INSERT INTO orders 
            (order_code, table_id, order_type, status, payment_status, total_amount, discount_amount, tax_amount, note, created_by_user_id, created_at, kitchen_print_count) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), 0)`,
            [
                orderData.order_code,
                orderData.table_id,
                orderData.order_type,
                orderData.status,
                orderData.payment_status,
                orderData.total_amount,
                orderData.discount_amount || 0,
                orderData.tax_amount || 0,
                orderData.note,
                orderData.created_by_user_id
            ]
        );

        const newOrderId = orderResult.insertId;
        if (orderData.order_type === 'DINE_IN' && orderData.table_id) {
            await connection.query(
                "UPDATE tables SET status = 'OCCUPIED', current_order_id = ? WHERE table_id = ?",
                [newOrderId, orderData.table_id]
            );
        }
        
        if (orderData.items && orderData.items.length > 0) {
            for (const item of orderData.items) {
                const [detailResult] = await connection.query(
                    `INSERT INTO order_details 
                    (order_id, product_id, product_name, price, quantity, total_line_amount, note, item_status) 
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
                    [
                        newOrderId,
                        item.product_id,
                        item.product_name,
                        item.price,
                        item.quantity,
                        item.total_line_amount,
                        item.note || '',
                        'PENDING'
                    ]
                );

                const newDetailId = detailResult.insertId;

                if (item.modifiers && item.modifiers.length > 0) {
                    const modifierValues = item.modifiers.map(mod => [
                        newDetailId,
                        mod.id,
                        mod.name,
                        mod.extraPrice,
                        1,
                        mod.userInput || mod.note || null
                    ]);

                    await connection.query(
                        `INSERT INTO order_modifier_details 
                        (order_detail_id, modifier_id, modifier_name, price, quantity, modifier_note) 
                        VALUES ?`,
                        [modifierValues]
                    );
                }
            }
        }

        await connection.commit();
        console.log(`Đơn hàng đã được tạo: ${orderData.order_code}`);
        
        res.status(201).json({ 
            message: 'Tạo đơn hàng thành công', 
            order_id: newOrderId,
            order_code: orderData.order_code 
        });

    } catch (error) {
        await connection.rollback();
        console.error('Lỗi khi tạo đơn hàng:', error);
        res.status(500).json({ message: 'Lỗi server khi tạo đơn hàng', error: error.message });
    } finally {
        connection.release();
    }
};

exports.getPendingOrders = async (req, res) => {
    try {
        const query = `
            SELECT 
                o.order_id, 
                o.order_code, 
                o.table_id,
                t.table_name,
                o.total_amount, 
                o.created_at 
            FROM orders o
            LEFT JOIN tables t ON o.table_id = t.table_id
            WHERE o.status = 'PENDING' 
            ORDER BY o.created_at DESC
        `;
        const [rows] = await db.query(query);
        res.status(200).json(rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Lỗi lấy danh sách đơn chờ' });
    }
};

exports.getOrderById = async (req, res) => {
    try {
        const orderId = req.params.id;

        const query = `
            SELECT o.*, t.table_name 
            FROM orders o
            LEFT JOIN tables t ON o.table_id = t.table_id
            WHERE o.order_id = ?
        `;
        const [orderRows] = await db.query(query, [orderId]);
        if (orderRows.length === 0) return res.status(404).json({ message: 'Không tìm thấy đơn hàng' });
        const order = orderRows[0];

        const [itemRows] = await db.query('SELECT * FROM order_details WHERE order_id = ?', [orderId]);

        const itemsWithModifiers = [];
        
        for (const item of itemRows) {
            const [modRows] = await db.query(
                `SELECT 
                    modifier_id as id, 
                    modifier_name as name, 
                    price as extraPrice, 
                    modifier_note as userInput
                 FROM order_modifier_details 
                 WHERE order_detail_id = ?`, 
                [item.order_detail_id]
            );
            
            const modifiers = modRows.map(m => ({
                ...m,
                extraPrice: parseFloat(m.extraPrice)
            }));

            itemsWithModifiers.push({
                ...item,
                price: parseFloat(item.price),
                total_line_amount: parseFloat(item.total_line_amount),
                modifiers: modifiers
            });
        }

        const fullOrder = {
            ...order,
            total_amount: parseFloat(order.total_amount),
            items: itemsWithModifiers
        };

        res.status(200).json(fullOrder);

    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Lỗi lấy chi tiết đơn hàng' });
    }
};

exports.updateOrder = async (req, res) => {
    const connection = await db.getConnection();
    try {
        await connection.beginTransaction();

        const orderId = req.params.id;
        const orderData = req.body;

        const [oldOrderRows] = await connection.query(
            "SELECT table_id FROM orders WHERE order_id = ?", 
            [orderId]
        );
        let oldTableId = null;
        if (oldOrderRows.length > 0) {
            oldTableId = oldOrderRows[0].table_id;
        }

        const [checkRows] = await connection.query(
            "SELECT status FROM orders WHERE order_id = ? AND status = 'PENDING'", 
            [orderId]
        );
        if (checkRows.length === 0) {
            await connection.rollback();
            return res.status(400).json({ message: 'Đơn hàng không tồn tại hoặc đã hoàn thành, không thể sửa.' });
        }

        await connection.query(
            `UPDATE orders SET 
                table_id = ?, 
                order_type = ?, 
                total_amount = ?, 
                discount_amount = ?, 
                tax_amount = ?, 
                note = ?,
                payment_status = ? 
            WHERE order_id = ?`,
            [
                orderData.table_id,
                orderData.order_type,
                orderData.total_amount,
                orderData.discount_amount || 0,
                orderData.tax_amount || 0,
                orderData.note,
                orderData.payment_status,
                orderId
            ]
        );

        if (orderData.table_id && oldTableId && oldTableId !== orderData.table_id) {
            await connection.query(
                "UPDATE tables SET status = 'AVAILABLE', current_order_id = NULL WHERE table_id = ?",
                [oldTableId]
            );

            await connection.query(
                "UPDATE tables SET status = 'OCCUPIED', current_order_id = ? WHERE table_id = ?",
                [orderId, orderData.table_id]
            );
        }
        else if (orderData.order_type === 'DINE_IN' && orderData.table_id) {
            await connection.query(
                "UPDATE tables SET status = 'OCCUPIED', current_order_id = ? WHERE table_id = ?",
                [orderId, orderData.table_id]
            );
        }

        let targetItemStatus = 'PENDING';
        if (orderData.status === 'COMPLETED') {
            await connection.query("UPDATE orders SET status = 'COMPLETED', completed_at = NOW() WHERE order_id = ?", [orderId]);
        
            await connection.query(
                "UPDATE tables SET status = 'CLEANING', current_order_id = NULL WHERE current_order_id = ?",
                [orderId]
            );

            targetItemStatus = 'SERVED';

            // await connection.query(
            //     "UPDATE order_details SET item_status = 'SERVED' WHERE order_id = ?",
            //     [orderId]
            // );
        }

        if (orderData.status === 'CANCELLED') {
             await connection.query(
                "UPDATE order_details SET item_status = 'CANCELLED' WHERE order_id = ?",
                [orderId]
            );
        }

        await connection.query('DELETE FROM order_details WHERE order_id = ?', [orderId]);

        if (orderData.items && orderData.items.length > 0) {
            for (const item of orderData.items) {
                const [detailResult] = await connection.query(
                    `INSERT INTO order_details 
                    (order_id, product_id, product_name, price, quantity, total_line_amount, note, item_status) 
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
                    [
                        orderId,
                        item.product_id,
                        item.product_name,
                        item.price,
                        item.quantity,
                        item.total_line_amount,
                        item.note || '',
                        targetItemStatus
                    ]
                );
                
                const newDetailId = detailResult.insertId;

                if (item.modifiers && item.modifiers.length > 0) {
                    const modifierValues = item.modifiers.map(mod => [
                        newDetailId,
                        mod.id.toString(),
                        mod.name,
                        parseFloat(mod.extraPrice),
                        1,
                        mod.userInput || mod.note || null
                    ]);
                    await connection.query(
                        `INSERT INTO order_modifier_details 
                        (order_detail_id, modifier_id, modifier_name, price, quantity, modifier_note) 
                        VALUES ?`,
                        [modifierValues]
                    );
                }
            }
        }

        await connection.query(
            `INSERT INTO order_logs (order_id, old_status, new_status, action, changed_by_user_id, note) 
             VALUES (?, 'PENDING', ?, 'UPDATE', ?, 'Cập nhật đơn hàng')`,
            [orderId, orderData.status, orderData.created_by_user_id]
        );

        await connection.commit();
        res.status(200).json({ message: 'Cập nhật đơn hàng thành công', order_id: orderId });

    } catch (error) {
        await connection.rollback();
        console.error('Lỗi update:', error);
        res.status(500).json({ message: 'Lỗi server khi cập nhật đơn' });
    } finally {
        connection.release();
    }
};

exports.incrementPrintCount = async (req, res) => {
    const connection = await db.getConnection();
    try {
        const orderId = req.params.id;
        
        await connection.query(
            "UPDATE orders SET kitchen_print_count = kitchen_print_count + 1 WHERE order_id = ?",
            [orderId]
        );

        const [rows] = await connection.query("SELECT kitchen_print_count FROM orders WHERE order_id = ?", [orderId]);
        
        const newCount = rows[0]?.kitchen_print_count || 1;

        res.status(200).json({ print_count: newCount });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Lỗi cập nhật số lần in' });
    } finally {
        connection.release();
    }
};