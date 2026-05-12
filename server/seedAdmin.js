const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const UserSchema = new mongoose.Schema({
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    role: { type: String, enum: ['buyer', 'admin'], default: 'buyer' },
    createdAt: { type: Date, default: Date.now }
});

const User = mongoose.model('User', UserSchema);

async function seedAdmin() {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('✅ Connected to MongoDB for seeding');

        const adminEmail = 'admin@farmnex.com';
        const existingAdmin = await User.findOne({ email: adminEmail });

        if (existingAdmin) {
            console.log('ℹ️ Admin already exists in database');
        } else {
            const hashedPassword = await bcrypt.hash('admin123', 10);
            const admin = new User({
                name: 'Admin User',
                email: adminEmail,
                password: hashedPassword,
                role: 'admin'
            });
            await admin.save();
            console.log('🚀 Admin account seeded successfully!');
        }
        
        await mongoose.connection.close();
        process.exit(0);
    } catch (err) {
        console.error('❌ Seeding error:', err);
        process.exit(1);
    }
}

seedAdmin();
