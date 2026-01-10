const db = require('../config/db');

// 1. Lấy toàn bộ danh sách Nhóm và Modifier (Dạng cây cha-con)
exports.getAllModifiers = async (req, res) => {
    try {
        // Lấy nhóm trước
        const [groups] = await db.query("SELECT * FROM modifier_groups ORDER BY group_id DESC");
        
        // Lấy tất cả modifier
        const [modifiers] = await db.query("SELECT * FROM modifiers ORDER BY modifier_id DESC");

        // Ghép modifier vào group tương ứng
        const result = groups.map(group => {
            return {
                ...group,
                modifiers: modifiers.filter(m => m.group_id === group.group_id)
            };
        });

        res.status(200).json(result);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Lỗi lấy danh sách tùy chọn' });
    }
};

// 2. Tạo Nhóm mới (Modifier Group)
exports.createGroup = async (req, res) => {
    try {
        const { group_name, is_multi_select, is_required } = req.body;
        
        if (!group_name) return res.status(400).json({ message: 'Thiếu tên nhóm' });

        const [result] = await db.query(
            "INSERT INTO modifier_groups (group_name, is_multi_select, is_required) VALUES (?, ?, ?)",
            [group_name, is_multi_select ? 1 : 0, is_required ? 1 : 0]
        );
        
        res.status(201).json({ message: 'Tạo nhóm thành công', id: result.insertId });
    } catch (error) {
        res.status(500).json({ message: 'Lỗi tạo nhóm' });
    }
};

// 3. Tạo Modifier mới (Gắn vào Group)
exports.createModifier = async (req, res) => {
    try {
        const { modifier_name, group_id, extra_price, is_input_required } = req.body;

        if (!modifier_name || !group_id) return res.status(400).json({ message: 'Thiếu thông tin' });

        await db.query(
            "INSERT INTO modifiers (modifier_name, group_id, extra_price, is_input_required) VALUES (?, ?, ?, ?)",
            [modifier_name, group_id, extra_price || 0, is_input_required ? 1 : 0]
        );

        res.status(201).json({ message: 'Thêm tùy chọn thành công' });
    } catch (error) {
        res.status(500).json({ message: 'Lỗi thêm tùy chọn' });
    }
};

// 4. Cập nhật Modifier (Sửa tên/giá)
exports.updateModifier = async (req, res) => {
    try {
        const { id } = req.params;
        const { modifier_name, extra_price } = req.body;
        
        await db.query(
            "UPDATE modifiers SET modifier_name = ?, extra_price = ? WHERE modifier_id = ?",
            [modifier_name, extra_price, id]
        );
        res.status(200).json({ message: 'Cập nhật thành công' });
    } catch (error) {
        res.status(500).json({ message: 'Lỗi cập nhật' });
    }
};

// 5. Xóa Modifier
exports.deleteModifier = async (req, res) => {
    try {
        await db.query("DELETE FROM modifiers WHERE modifier_id = ?", [req.params.id]);
        res.status(200).json({ message: 'Đã xóa' });
    } catch (error) {
        res.status(500).json({ message: 'Lỗi xóa' });
    }
};