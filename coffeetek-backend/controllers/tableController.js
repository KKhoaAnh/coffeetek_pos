const db = require('../config/db');

exports.getTables = async (req, res) => {
    try {
        const [rows] = await db.query('SELECT * FROM tables');
        res.status(200).json(rows);
    } catch (error) {
        res.status(500).json({ message: 'Lỗi lấy danh sách bàn' });
    }
};

exports.clearTable = async (req, res) => {
    try {
        const tableId = req.params.id;
        await db.query("UPDATE tables SET status = 'AVAILABLE', current_order_id = NULL WHERE table_id = ?", [tableId]);
        res.status(200).json({ message: 'Đã dọn bàn xong' });
    } catch (error) {
        res.status(500).json({ message: 'Lỗi cập nhật bàn' });
    }
};

// --- [SỬA ĐỔI]: LOGIC CHUYỂN BÀN KHỚP VỚI FRONTEND ---
exports.moveTable = async (req, res) => {
    const connection = await db.getConnection();
    try {
        await connection.beginTransaction();

        // Frontend gửi lên: { orderId, targetTableId }
        const { orderId, targetTableId } = req.body;

        if (!orderId || !targetTableId) {
            throw new Error("Thiếu thông tin đơn hàng hoặc bàn đích");
        }

        // 1. Tìm bàn hiện tại dựa vào orderId
        const [currentOrderCheck] = await connection.query(
            "SELECT table_id FROM orders WHERE order_id = ?", 
            [orderId]
        );

        if (currentOrderCheck.length === 0) {
            throw new Error("Không tìm thấy đơn hàng");
        }
        const currentTableId = currentOrderCheck[0].table_id;

        // 2. Kiểm tra bàn đích
        const [targetCheck] = await connection.query("SELECT status FROM tables WHERE table_id = ?", [targetTableId]);
        if (targetCheck.length === 0) throw new Error("Bàn đích không tồn tại");
        
        // Chỉ cho phép chuyển sang bàn TRỐNG (AVAILABLE)
        if (targetCheck[0].status !== 'AVAILABLE') {
            throw new Error("Bàn đích đang có khách, vui lòng chọn Gộp bàn hoặc bàn khác.");
        }

        // 3. Thực hiện chuyển đổi
        const moveNote = `\n[Chuyển bàn]: Từ bàn ${currentTableId} sang bàn ${targetTableId}`;
        
        // Cập nhật Order: Đổi table_id và thêm ghi chú
        await connection.query(
            `UPDATE orders 
             SET table_id = ?, 
                 note = CONCAT(IFNULL(note, ''), ?) 
             WHERE order_id = ?`, 
            [targetTableId, moveNote, orderId]
        );

        // Cập nhật Bàn Đích: Thành OCCUPIED
        await connection.query(
            "UPDATE tables SET status = 'OCCUPIED', current_order_id = ? WHERE table_id = ?", 
            [orderId, targetTableId]
        );

        // Cập nhật Bàn Cũ: Thành AVAILABLE
        await connection.query(
            "UPDATE tables SET status = 'AVAILABLE', current_order_id = NULL WHERE table_id = ?", 
            [currentTableId]
        );

        // Ghi Log
        await connection.query(
            `INSERT INTO order_logs (order_id, action, note) VALUES (?, 'MOVE_TABLE', ?)`,
            [orderId, `Chuyển từ bàn ${currentTableId} sang bàn ${targetTableId}`]
        );

        await connection.commit();
        res.status(200).json({ message: 'Chuyển bàn thành công' });

    } catch (error) {
        await connection.rollback();
        console.error(error);
        res.status(500).json({ message: error.message || 'Lỗi hệ thống khi chuyển bàn' });
    } finally {
        connection.release();
    }
};

// --- [SỬA ĐỔI]: LOGIC GỘP BÀN KHỚP VỚI FRONTEND ---
exports.mergeTable = async (req, res) => {
    const connection = await db.getConnection();
    try {
        await connection.beginTransaction();

        // Frontend gửi lên: { sourceOrderId, targetTableId }
        const { sourceOrderId, targetTableId } = req.body;

        if (!sourceOrderId || !targetTableId) {
            throw new Error("Thiếu thông tin để gộp bàn");
        }

        // 1. Lấy thông tin bàn Nguồn (từ sourceOrderId)
        const [sourceOrderInfo] = await connection.query(
            "SELECT table_id FROM orders WHERE order_id = ?", 
            [sourceOrderId]
        );
        if (sourceOrderInfo.length === 0) throw new Error("Đơn hàng gốc không tồn tại");
        const sourceTableId = sourceOrderInfo[0].table_id;

        // 2. Lấy thông tin bàn Đích (targetTableId)
        const [targetTableInfo] = await connection.query(
            "SELECT current_order_id, status FROM tables WHERE table_id = ?", 
            [targetTableId]
        );

        if (targetTableInfo.length === 0) throw new Error("Bàn đích không tồn tại");
        const targetOrderId = targetTableInfo[0].current_order_id;

        // Kiểm tra hợp lệ: Bàn đích phải đang có đơn hàng
        if (!targetOrderId) {
            throw new Error("Bàn đích đang trống, hãy dùng chức năng Chuyển bàn.");
        }

        // 3. Chuyển tất cả món từ Source Order sang Target Order
        await connection.query(
            "UPDATE order_details SET order_id = ? WHERE order_id = ?", 
            [targetOrderId, sourceOrderId]
        );

        // 4. Tính lại tổng tiền cho Target Order
        const [sumResult] = await connection.query(
            "SELECT SUM(total_line_amount) as total FROM order_details WHERE order_id = ?",
            [targetOrderId]
        );
        const newTotal = sumResult[0].total || 0;

        await connection.query("UPDATE orders SET total_amount = ? WHERE order_id = ?", [newTotal, targetOrderId]);

        // 5. Hủy Source Order (vì món đã chuyển hết đi rồi)
        await connection.query(
            "UPDATE orders SET status = 'CANCELLED', total_amount = 0, note = CONCAT(IFNULL(note,''), ' [Đã gộp sang đơn khác]') WHERE order_id = ?", 
            [sourceOrderId]
        );

        // 6. Giải phóng bàn Nguồn
        await connection.query(
            "UPDATE tables SET status = 'AVAILABLE', current_order_id = NULL WHERE table_id = ?", 
            [sourceTableId]
        );

        // 7. Ghi Log
        await connection.query(
            `INSERT INTO order_logs (order_id, action, note) VALUES (?, 'MERGE_TABLE', ?)`,
            [targetOrderId, `Gộp đơn từ bàn ${sourceTableId} (Order #${sourceOrderId}) sang`]
        );

        await connection.commit();
        res.status(200).json({ message: 'Gộp bàn thành công' });

    } catch (error) {
        await connection.rollback();
        console.error(error);
        res.status(500).json({ message: error.message || 'Lỗi hệ thống khi gộp bàn' });
    } finally {
        connection.release();
    }
};

// controllers/tableController.js

exports.updateTablePositions = async (req, res) => {
    const connection = await db.getConnection();
    try {
        await connection.beginTransaction();

        const tables = req.body; 
        
        if (!Array.isArray(tables) || tables.length === 0) {
            throw new Error("Dữ liệu không hợp lệ");
        }

        for (const table of tables) {
            await connection.query(
                `UPDATE tables 
                 SET pos_x = ?, pos_y = ?, width = ?, height = ?, shape = ?, color = ? 
                 WHERE table_id = ?`,
                [
                    table.x, 
                    table.y, 
                    table.width || 0.15, 
                    table.height || 0.15, 
                    table.shape,
                    table.color || '#FFFFFF', // [THÊM] Lưu màu (Hex string)
                    table.id
                ]
            );
        }

        await connection.commit();
        res.status(200).json({ message: 'Đã cập nhật sơ đồ bàn thành công' });

    } catch (error) {
        await connection.rollback();
        console.error(error);
        res.status(500).json({ message: 'Lỗi cập nhật sơ đồ: ' + error.message });
    } finally {
        connection.release();
    }
};