const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');

router.post('/', orderController.createOrder);

router.get('/pending', orderController.getPendingOrders);

router.get('/:id', orderController.getOrderById);

router.put('/:id', orderController.updateOrder);

router.put('/:id/print-count', orderController.incrementPrintCount);

module.exports = router;