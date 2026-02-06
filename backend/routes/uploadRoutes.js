const express = require('express');
const router = express.Router();
const upload = require('../config/cloudinaryConfig');

// Generic Upload (Single Image)
router.post('/image', upload.single('image'), (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ message: 'No file uploaded' });
        }
        res.json({ url: req.file.path });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Server Error during upload' });
    }
});

module.exports = router;
