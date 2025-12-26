const express = require('express');
const router = express.Router();
const tableController = require('../controllers/tableController');

router.get('/', tableController.getTables);
router.put('/:id/clear', tableController.clearTable);
router.post('/move', tableController.moveTable);
router.post('/merge', tableController.mergeTable);
router.put('/positions', tableController.updateTablePositions);

module.exports = router;