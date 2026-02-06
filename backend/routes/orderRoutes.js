const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');

router.post('/', orderController.createOrder); // Create new order
router.get('/', orderController.getOrders); // Get user orders
router.patch('/:orderId/approve', orderController.approveOrder); // Approve/Reject Order

module.exports = router;
