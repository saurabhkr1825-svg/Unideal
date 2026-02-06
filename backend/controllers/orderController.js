const Order = require('../models/Order');
const Product = require('../models/Product');

exports.createOrder = async (req, res) => {
    try {
        const { productId, amount, type, buyerId, startDate, endDate, proofImage } = req.body;

        const product = await Product.findById(productId);
        if (!product) return res.status(404).json({ message: 'Product not found' });

        if (product.status !== 'approved' && product.status !== 'rented') {
            // Note: For rent, we might allow multiple rents if dates don't overlap, 
            // but for Phase 2 MVP let's keep it simple: if 'rented' it's taken for now.
            // Or actually, if 'rented', the status stays 'rented' until returned? 
            // Let's assume strict locking for now. 
            // Better check:
            if (type === 'buy' && product.status !== 'approved') {
                return res.status(400).json({ message: 'Product is not available for purchase' });
            }
        }

        // Create Order
        const order = new Order({
            buyer: buyerId,
            product: productId,
            amount,
            type,
            startDate,
            endDate,
            proofImage,
            status: 'pending_approval' // Default start state
        });

        await order.save();

        // Release Lock immediately since Order is created (even if pending)
        // The Seller has to approve it. If rejected, item becomes free again?
        // Actually, if we release lock, someone else can buy it?
        // Ideally, we should keep it "reserved" or "locked" until approved/rejected.
        // For MVP Phase 2: Let's release the "temporary lock" (10min) but maybe 
        // we need a "pending" status on Product to prevent double booking?
        // Let's set Product to 'isLocked: false' but leave status as 'approved'.
        // Wait, if it's 'pending_approval', another user could buy it.
        // FIX: Let's NOT change product status yet, but maybe re-lock it or 
        // trust the 'pending_approval' order to block others? 
        // For simplicity: We clear the 10-min lock. 
        // If another user tries to buy, we need to check if there are pending orders?
        // Let's stick to: Clear Lock. Race conditions might happen if Seller has 2 pending orders.
        // Seller can choose which one to approve.

        product.isLocked = false;
        product.lockedBy = null;
        product.lockExpiresAt = null;

        await product.save();

        res.status(201).json(order);
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Server Error' });
    }
};

exports.getOrders = async (req, res) => {
    try {
        const { userId, role } = req.query;

        if (!userId) return res.status(400).json({ message: 'User ID required' });
        // Simple check if userId looks like ObjectId (24 chars hex)
        if (!userId.match(/^[0-9a-fA-F]{24}$/)) {
            return res.json([]);
        }

        let query = {};
        if (role === 'seller') {
            // Find products sold by this user, then find orders for those products
            // A bit complex with NoSQL joins. 
            // Alternative: Find orders, populate product, filter in memory (easier for MVP)
            // Or better:
            const products = await Product.find({ seller: userId }).select('_id');
            const productIds = products.map(p => p._id);
            query = { product: { $in: productIds } };
        } else {
            query = { buyer: userId };
        }

        const orders = await Order.find(query)
            .populate('product')
            .populate('buyer', 'name email') // Show buyer info to seller
            .sort({ createdAt: -1 });

        res.json(orders);
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Server Error' });
    }
};

exports.approveOrder = async (req, res) => {
    try {
        const { orderId } = req.params;
        const { action } = req.body; // 'approve' or 'reject'

        const order = await Order.findById(orderId).populate('product');
        if (!order) return res.status(404).json({ message: 'Order not found' });

        if (action === 'approve') {
            if (order.type === 'buy') {
                order.status = 'completed';
                order.product.status = 'sold';
            } else {
                order.status = 'rented';
                order.product.status = 'rented';
                // In a real app, rent would expire automatically or be returned manually
            }
        } else if (action === 'reject') {
            order.status = 'rejected';
            // Product stays 'approved' (available)
        }

        await order.save();
        await order.product.save();

        res.json(order);
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Server Error' });
    }
};
