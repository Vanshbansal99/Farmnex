const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
require('dotenv').config();

const app = express();

// 🛡️ Standard Production Middleware
app.use(express.json());
app.use(cors({
    origin: '*', // For production, replace with your specific Vercel frontend URL
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(helmet({
    crossOriginResourcePolicy: false,
    contentSecurityPolicy: false
}));
app.use(morgan('dev'));

// 📡 MongoDB Connection Manager (Serverless Optimized)
const connectDB = async () => {
    if (mongoose.connection.readyState >= 1) return;
    
    try {
        const MONGO_URI = process.env.MONGO_URI;
        if (!MONGO_URI) throw new Error('MONGO_URI is missing in environment variables');
        
        await mongoose.connect(MONGO_URI);
        console.log('✅ Connected to MongoDB Atlas');
    } catch (err) {
        console.error('❌ MongoDB Connection Error:', err.message);
    }
};

// Ensure DB is connected for every request
app.use(async (req, res, next) => {
    await connectDB();
    next();
});

// 🛣️ Standard Route Definitions
app.get('/', (req, res) => {
    res.json({ status: 'Online', platform: 'FarmNex API', version: '1.0.0' });
});

// Static path for legacy uploads (Note: Cloudinary preferred for production)
const path = require('path');
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// API Routes
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/products', require('./routes/productRoutes'));
app.use('/api/orders', require('./routes/orderRoutes'));
app.use('/api/admin', require('./routes/adminRoutes'));
app.use('/api/catalogues', require('./routes/catalogueRoutes'));

// 🚨 Global Error Handler (Professional Standard)
app.use((err, req, res, next) => {
    console.error(`💥 Error: ${err.message}`);
    res.status(err.status || 500).json({
        success: false,
        message: err.message || 'Internal Server Error',
        stack: process.env.NODE_ENV === 'development' ? err.stack : undefined
    });
});

// 🚀 Local Startup (Only runs during development)
const PORT = process.env.PORT || 5000;
if (process.env.NODE_ENV !== 'production') {
    app.listen(PORT, () => {
        console.log(`📡 Local Dev Server: http://localhost:${PORT}`);
    });
}

// ☁️ Cloud Export
module.exports = app;
