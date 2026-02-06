const mongoose = require('mongoose');

const orderSchema = new mongoose.Schema({
    buyer: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    product: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Product',
        required: true
    },
    amount: {
        type: Number,
        required: true
    },
    type: {
        type: String,
        enum: ['buy', 'rent'],
        default: 'buy'
    },
    // Rent specific
    startDate: { type: Date },
    endDate: { type: Date },

    // Trust & Verification
    proofImage: { type: String }, // URL to uploaded screenshot

    status: {
        type: String,
        enum: ['pending_approval', 'completed', 'rented', 'cancelled', 'rejected'],
        default: 'pending_approval'
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('Order', orderSchema);
