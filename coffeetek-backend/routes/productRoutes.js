const express = require('express');
const router = express.Router();
const productController = require('../controllers/productController');

router.get('/', productController.getProducts);

router.get('/:id/modifiers', productController.getProductModifiers);

module.exports = router;