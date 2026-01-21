const express = require('express');
const router = express.Router();
const tableController = require('../controllers/tableController');

router.get('/', tableController.getTables);
router.put('/:id/clear', tableController.clearTable);
router.post('/move', tableController.moveTable);
router.post('/merge', tableController.mergeTable);
router.put('/positions', tableController.updateTablePositions);
router.post('/', tableController.createTable);           // Thêm bàn
router.put('/:id/info', tableController.updateTableInfo); // Sửa bàn (Tên, Màu, Active)
router.delete('/:id', tableController.deleteTable);
module.exports = router;