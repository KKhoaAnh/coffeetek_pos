const express = require('express');
const router = express.Router();
const reportController = require('../controllers/reportController');

router.get('/summary', reportController.getSummaryReport);
router.get('/category', reportController.getCategoryReport);
router.get('/product', reportController.getProductReport);

module.exports = router;