const Product = require('../models/Product');

exports.createProduct = async (req, res) => {
    try {
        const { name, description, category, condition, allowBuy, allowRent, allowDonate, price, rentPrice, allowReturn, sellerId } = req.body;

        // Handle files
        // req.files is an object with arrays if using multer fields
        // Assuming 'images' and 'video' fields
        let imageUrls = [];
        let videoUrl = '';

        if (req.files && req.files.images) {
            imageUrls = req.files.images.map(file => file.path);
        }

        if (req.files && req.files.video) {
            videoUrl = req.files.video[0].path;
        }

        const newProduct = new Product({
            name,
            description,
            category,
            condition,
            allowBuy: allowBuy === 'true',
            allowRent: allowRent === 'true',
            allowDonate: allowDonate === 'true',
            allowReturn: allowReturn === 'true',
            price: price ? Number(price) : 0,
            rentPrice: rentPrice ? Number(rentPrice) : 0,
            images: imageUrls,
            video: videoUrl,
            seller: sellerId, // Sent from client or extracted from token middleware
            status: 'pending' // Default
        });

        await newProduct.save();
        res.status(201).json(newProduct);

    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Server Error' });
    }
};

exports.getProducts = async (req, res) => {
    try {
        const { category, search } = req.query;
        let query = { status: 'approved' };

        if (category) query.category = category;
        if (search) {
            query.name = { $regex: search, $options: 'i' };
        }

        const products = await Product.find(query).sort({ createdAt: -1 }).populate('seller', 'userId email');
        res.json(products);
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Server Error' });
    }
};

// Admin only (Middleware should check role)
exports.updateProductStatus = async (req, res) => {
    try {
        const { status } = req.body; // approved, rejected
        const product = await Product.findByIdAndUpdate(req.params.id, { status }, { new: true });
        res.json(product);
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Server Error' });
    }
};

exports.lockProduct = async (req, res) => {
    try {
        const { userId } = req.body; // Or get from req.user
        const product = await Product.findById(req.params.id);

        if (!product) return res.status(404).json({ message: 'Product not found' });

        if (product.isLocked && product.lockExpiresAt > Date.now()) {
            if (product.lockedBy.toString() !== userId) {
                return res.status(409).json({ message: 'Product is currently being purchased by someone else' });
            }
            // If same user, extend lock or ignore
        }

        // Lock it
        product.isLocked = true;
        product.lockedBy = userId;
        product.lockExpiresAt = Date.now() + 10 * 60 * 1000; // 10 minutes
        await product.save();

        res.json({ message: 'Product locked for purchase', lockExpiresAt: product.lockExpiresAt });

    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Server Error' });
    }
};
