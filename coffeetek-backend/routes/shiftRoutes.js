const express = require('express');
const router = express.Router();
const shiftController = require('../controllers/shiftController');

// Đổi tên endpoint cho đúng ý nghĩa
router.get('/today', shiftController.getTodayShifts); 
router.get('/summary', shiftController.getShiftSummary); // [MỚI]
router.post('/open', shiftController.openShift);
router.post('/close', shiftController.closeShift);

module.exports = router;