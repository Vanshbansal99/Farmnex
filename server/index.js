const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
require('dotenv').config();

const app = express();

// 🛡️ Standard Production Middleware
app.use(express.json());
app.use(cors({
    origin: '*', 
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(helmet({
    crossOriginResourcePolicy: false,
    contentSecurityPolicy: false
}));
app.use(morgan('dev'));

// 📡 MongoDB Connection Manager (Hardened & Fast-Fail)
let cachedDb = null;
let connectionError = null;

const connectDB = async () => {
    // If already connected, return
    if (mongoose.connection.readyState === 1) return;
    
    // If currently connecting, wait for it
    if (mongoose.connection.readyState === 2) return;

    const MONGO_URI = process.env.MONGO_URI;
    if (!MONGO_URI) {
        connectionError = 'MONGO_URI is missing';
        return;
    }

    try {
        console.log('📡 Attempting to connect to MongoDB Atlas...');
        await mongoose.connect(MONGO_URI, {
            serverSelectionTimeoutMS: 5000, // Fail fast after 5s instead of 10s
            connectTimeoutMS: 10000,
            family: 4 // Force IPv4 (Fixes many DNS issues on Vercel/Local)
        });
        console.log('✅ MongoDB Atlas Connected Successfully');
        connectionError = null;
    } catch (err) {
        connectionError = err.message;
        console.error('❌ MongoDB Connection Critical Error:', err.message);
        throw err; // Let the middleware catch it
    }
};

// 🛡️ Smooth Onboarding Middleware: Check DB Health before every request
app.use(async (req, res, next) => {
    try {
        // Skip DB check for the root health check route
        if (req.url === '/') return next();
        
        await connectDB();
        next();
    } catch (err) {
        console.error('🛑 Request Blocked: Database Unavailable');
        res.status(503).json({ 
            success: false, 
            message: 'Database connection is temporarily unavailable. Please check IP whitelisting.',
            error: err.message
        });
    }
});

// 🛣️ Standard Route Definitions
app.get('/', (req, res) => {
    res.json({ 
        status: 'Online', 
        db_status: mongoose.connection.readyState === 1 ? 'Connected' : 'Disconnected',
        platform: 'FarmNex Cloud API'
    });
});

// Static path for existing assets (Read-Only)
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// API Routes
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/products', require('./routes/productRoutes'));
app.use('/api/orders', require('./routes/orderRoutes'));
app.use('/api/admin', require('./routes/adminRoutes'));
app.use('/api/catalogues', require('./routes/catalogueRoutes'));

// 🚨 Global Error Handler
app.use((err, req, res, next) => {
    console.error(`💥 [CRITICAL] ${req.method} ${req.url} - ${err.message}`);
    res.status(err.status || 500).json({
        success: false,
        message: err.message || 'Internal Server Error',
    });
});

// 🚀 Startup Logic
const PORT = process.env.PORT || 5000;
if (process.env.NODE_ENV !== 'production') {
    app.listen(PORT, () => {
        console.log(`📡 Local Dev: http://localhost:${PORT}`);
    });
}

// ☁️ Cloud Export
module.exports = app;
