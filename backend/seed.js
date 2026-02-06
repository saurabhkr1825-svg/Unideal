require('dotenv').config();
const mongoose = require('mongoose');
const Product = require('./models/Product');
const User = require('./models/User');

mongoose.connect(process.env.MONGO_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
})
    .then(async () => {
        console.log('MongoDB Connected');
        await seedData();
    })
    .catch(err => console.error(err));

async function seedData() {
    try {
        // Find a seller (or create one)
        let seller = await User.findOne({ email: 'admin@unideal.com' });
        if (!seller) {
            console.log('Creating Admin User for seeding...');
            // Simple mock user creation (ignoring password hash for seed simplicity if auth allows, 
            // but effectively we need a valid ID. If AuthController hashes password, we might need that logic.
            // For now, let's assume we can just create a user doc directly)
            seller = new User({
                name: 'Admin Seeder',
                email: 'admin@unideal.com',
                password: 'hashedpassword123', // Mock
                userId: 'ADMIN', // Added required field
                phone: '1234567890'
            });
            await seller.save();
        }

        const donationItems = [
            {
                name: 'Old Math Textbook',
                description: 'Grade 10 Mathematics textbook, slightly used.',
                category: 'Books',
                condition: 'Good',
                allowDonate: true,
                price: 0,
                images: ['https://via.placeholder.com/300?text=Math+Textbook'],
                seller: seller._id,
                status: 'approved'
            },
            {
                name: 'Winter Jacket',
                description: 'Blue winter jacket, size M. Good for cold weather.',
                category: 'Clothing',
                condition: 'Fair',
                allowDonate: true,
                price: 0,
                images: ['https://via.placeholder.com/300?text=Winter+Jacket'],
                seller: seller._id,
                status: 'approved'
            },
            {
                name: 'Canned Food Pack',
                description: 'Assorted canned vegetables and beans. Non-perishable.',
                category: 'Food',
                condition: 'New',
                allowDonate: true,
                price: 0,
                images: ['https://via.placeholder.com/300?text=Canned+Food'],
                seller: seller._id,
                status: 'approved'
            }
        ];

        const auctionItem = {
            name: 'Vintage Camera',
            description: 'Rare 1980s film camera. Working condition. Starting bid.',
            category: 'Electronics',
            condition: 'Good',
            allowAuction: true,
            allowBuy: true, // Usually auction items might have a "Buy Now" price
            price: 5000, // Starting price
            images: ['https://via.placeholder.com/300?text=Vintage+Camera'],
            seller: seller._id,
            status: 'approved'
        };

        await Product.insertMany([...donationItems, auctionItem]);

        console.log('✅ Added 3 Donation Items');
        console.log('✅ Added 1 Auction Item');

        process.exit();
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}
