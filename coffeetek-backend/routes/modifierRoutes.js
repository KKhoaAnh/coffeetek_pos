const express = require('express');
const router = express.Router();
const modifierController = require('../controllers/modifierController');

router.get('/', modifierController.getAllModifiers);
router.post('/group', modifierController.createGroup);
router.post('/item', modifierController.createModifier);
router.put('/item/:id', modifierController.updateModifier);
router.delete('/item/:id', modifierController.deleteModifier);

module.exports = router;