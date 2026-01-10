const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');

// Cấu hình nơi lưu ảnh
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'uploads/');
    },
    filename: (req, file, cb) => {
        cb(null, file.originalname); 
    }
});

const upload = multer({ storage: storage });

// API Upload
router.post('/', upload.single('image'), (req, res) => {
    if (!req.file) {
        return res.status(400).json({ message: 'Chưa chọn file' });
    }
    res.status(200).json({ filename: req.file.filename });
});

module.exports = router;