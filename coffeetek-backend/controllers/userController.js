const db = require('../config/db');

exports.getAllUsers = async (req, res) => {
    try {
        const [rows] = await db.query("SELECT * FROM users ORDER BY role, full_name");
        res.status(200).json(rows);
    } catch (error) {
        res.status(500).json({ message: 'Lỗi lấy danh sách nhân viên' });
    }
};

exports.createUser = async (req, res) => {
    try {
        const { username, full_name, role, pin_code } = req.body;

        if (!full_name || !pin_code) {
            return res.status(400).json({ message: 'Tên và mã PIN là bắt buộc' });
        }

        const [checkPin] = await db.query("SELECT user_id FROM users WHERE pin_code = ?", [pin_code]);
        if (checkPin.length > 0) {
            return res.status(400).json({ message: 'Mã PIN này đã được sử dụng!' });
        }

        const sql = `INSERT INTO users (username, full_name, role, pin_code, is_active, created_at) VALUES (?, ?, ?, ?, 1, NOW())`;
        await db.query(sql, [username || full_name, full_name, role || 'STAFF', pin_code]);

        res.status(201).json({ message: 'Thêm nhân viên thành công' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Lỗi thêm nhân viên' });
    }
};

exports.updateUser = async (req, res) => {
    try {
        const userId = req.params.id;
        const { full_name, role, pin_code } = req.body;

        await db.query(
            "UPDATE users SET full_name = ?, role = ?, pin_code = ? WHERE user_id = ?",
            [full_name, role, pin_code, userId]
        );

        res.status(200).json({ message: 'Cập nhật thành công' });
    } catch (error) {
        res.status(500).json({ message: 'Lỗi cập nhật nhân viên' });
    }
};

exports.toggleUserStatus = async (req, res) => {
    try {
        const userId = req.params.id;
        const { is_active } = req.body;

        let sql;
        let params;

        if (is_active) {
            sql = "UPDATE users SET is_active = 1, created_at = NOW() WHERE user_id = ?";
            params = [userId];
        } else {
            sql = "UPDATE users SET is_active = 0 WHERE user_id = ?";
            params = [userId];
        }

        await db.query(sql, params);

        res.status(200).json({ message: is_active ? 'Đã kích hoạt và làm mới ngày vào làm' : 'Đã khóa tài khoản' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Lỗi thay đổi trạng thái' });
    }
};