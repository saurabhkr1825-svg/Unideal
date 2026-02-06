const express = require('express');
const router = express.Router();
const productController = require('../controllers/productController');
const upload = require('../config/cloudinaryConfig');

// Upload Product (Supports multiple images and 1 video)
router.post('/upload', upload.fields([
    { name: 'images', maxCount: 4 },
    { name: 'video', maxCount: 1 }
]), productController.createProduct);

// Get Products (Public/User)
router.get('/', productController.getProducts);

// Admin Action (Status Update)
router.patch('/:id/status', productController.updateProductStatus);

// Lock Product (User Action)
router.post('/:id/lock', productController.lockProduct);

module.exports = router;
