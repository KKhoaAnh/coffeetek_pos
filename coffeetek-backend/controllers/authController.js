const db = require('../config/db');
const jwt = require('jsonwebtoken');
const dotenv = require('dotenv');

dotenv.config();
exports.loginWithPin = async (req, res) => {
    const { pin } = req.body;
    
    if (!pin) {
        return res.status(400).json({ message: 'Vui lòng nhập mã PIN' });
    }

    try {
        const [rows] = await db.query('SELECT * FROM users WHERE pin_code = ? AND is_active = 1', [pin]);

        if (rows.length === 0) {
            return res.status(401).json({ message: 'Mã PIN không đúng hoặc tài khoản bị khóa' });
        }

        const user = rows[0];

        const token = jwt.sign(
            { id: user.user_id, role: user.role },
            process.env.JWT_SECRET || 'secret_key',
            { expiresIn: '24h' }
        );

        res.status(200).json({
            message: 'Đăng nhập thành công',
            token: token,
            user: {
                user_id: user.user_id,
                full_name: user.full_name,
                role: user.role,
                avatar_url: user.avatar_url
            }
        });

    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Lỗi server' });
    }
};