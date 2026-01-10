const express = require('express');
const router = express.Router();
const productController = require('../controllers/productController');
const categoryController = require('../controllers/categoryController');

router.get('/', productController.getProducts);

router.get('/:id/modifiers', productController.getProductModifiers);
router.post('/', productController.createProduct);
router.put('/:id', productController.updateProduct);
router.patch('/:id/status', productController.toggleProductStatus);
router.get('/categories', categoryController.getAllCategories);
router.get('/:id/modifier-ids', productController.getProductModifierIds);
module.exports = router;