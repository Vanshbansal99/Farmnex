const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const app = express();

// 🛡️ Ensure Upload Directories Exist (Prevents "Directory Not Found" Crashes)
const uploadDirs = ['uploads', 'uploads/products', 'uploads/catalogues'];
uploadDirs.forEach(dir => {
    const fullPath = path.join(__dirname, dir);
    if (!fs.existsSync(fullPath)) {
        fs.mkdirSync(fullPath, { recursive: true });
        console.log(`📁 Created directory: ${dir}`);
    }
});

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

// 📡 MongoDB Connection Manager (Serverless Optimized)
const connectDB = async () => {
    if (mongoose.connection.readyState >= 1) return;
    
    try {
        const MONGO_URI = process.env.MONGO_URI;
        if (!MONGO_URI) throw new Error('MONGO_URI is missing in environment variables');
        
        await mongoose.connect(MONGO_URI, {
            serverSelectionTimeoutMS: 5000, // Timeout after 5s
        });
        console.log('✅ Connected to MongoDB Atlas');
    } catch (err) {
        console.error('❌ MongoDB Connection Error:', err.message);
    }
};

// Ensure DB is connected for every request
app.use(async (req, res, next) => {
    try {
        await connectDB();
        next();
    } catch (err) {
        res.status(503).json({ error: 'Database connection failed' });
    }
});

// 🛣️ Standard Route Definitions
app.get('/', (req, res) => {
    res.json({ status: 'Online', platform: 'FarmNex API', uptime: process.uptime() });
});

// Static path for uploads
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// API Routes
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/products', require('./routes/productRoutes'));
app.use('/api/orders', require('./routes/orderRoutes'));
app.use('/api/admin', require('./routes/adminRoutes'));
app.use('/api/catalogues', require('./routes/catalogueRoutes'));

// 🚨 Global Error Handler
app.use((err, req, res, next) => {
    console.error(`💥 [ERROR] ${req.method} ${req.url} - ${err.message}`);
    res.status(err.status || 500).json({
        success: false,
        message: err.message || 'Internal Server Error',
    });
});

// 🚀 Start Logic
const PORT = process.env.PORT || 5000;
if (process.env.NODE_ENV !== 'production') {
    app.listen(PORT, () => {
        console.log(`📡 Server Active: http://localhost:${PORT}`);
    }).on('error', (err) => {
        if (err.code === 'EADDRINUSE') {
            console.error(`⚠️ Port ${PORT} is busy. Try another port.`);
        } else {
            console.error('❌ Startup Error:', err);
        }
    });
}

// ☁️ Cloud Export
module.exports = app;
