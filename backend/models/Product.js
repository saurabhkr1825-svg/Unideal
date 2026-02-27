const mongoose = require('mongoose');

const productSchema = new mongoose.Schema({
    name: { type: String, required: true },
    description: { type: String, required: true },
    category: { type: String, required: true },
    condition: { type: String, required: true },

    // Options
    allowBuy: { type: Boolean, default: false },
    allowRent: { type: Boolean, default: false },
    allowDonate: { type: Boolean, default: false },
    allowAuction: { type: Boolean, default: false }, // New field
    allowReturn: { type: Boolean, default: false },

    // Pricing
    price: { type: Number }, // Buy price
    rentPrice: { type: Number }, // Rent per day

    // Media
    images: [{ type: String, required: true }],
    video: { type: String },

    // Administrative
    status: {
        type: String,
        enum: ['pending', 'approved', 'rejected', 'sold', 'rented'],
        default: 'pending'
    },

    // Locking Mechanism
    isLocked: { type: Boolean, default: false },
    lockedBy: { type: String, required: false }, // Changed to String for Supabase UUID
    lockExpiresAt: { type: Date },

    seller: {
        type: String, // Changed to String for Supabase UUID
        required: true
    },

    createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Product', productSchema);
