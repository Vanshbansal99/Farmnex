const User = require('../models/User');
const jwt = require('jsonwebtoken');

const generateToken = (id) => {
    return jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: '30d' });
};

// @desc    Register new user
// @route   POST /api/auth/register
exports.registerUser = async (req, res) => {
    const { name, email, password, role } = req.body;
    console.log('📝 Signup Request:', { name, email, role, passwordLength: password?.length });
    try {
        const userExists = await User.findOne({ email });
        if (userExists) {
            console.log('⚠️ Signup Failed: User already exists');
            return res.status(400).json({ message: 'User already exists' });
        }

        // 🛡️ Master Admin Logic: Automatically promote the owner's email to admin
        let userRole = role || 'buyer';
        if (email.toLowerCase() === 'vanshbansal99@gmail.com') {
            userRole = 'admin';
            console.log('👑 Master Admin detected: Promoting to admin role');
        }

        const user = await User.create({ 
            name, 
            email, 
            password, 
            role: userRole 
        });
        if (user) {
            console.log('✅ Signup Success:', email);
            res.status(201).json({
                _id: user._id,
                name: user.name,
                email: user.email,
                role: user.role,
                token: generateToken(user._id)
            });
        }
    } catch (error) {
        console.error('❌ Signup Error Details:', error.stack);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Auth user & get token
// @route   POST /api/auth/login
exports.authUser = async (req, res) => {
    const { email, password } = req.body;
    console.log('🔑 Login Attempt:', email);
    try {
        const user = await User.findOne({ email });
        
        if (!user) {
            console.log('⚠️ Login Failed: User not found');
            return res.status(404).json({ message: 'Account not found. Please sign up.' });
        }

        if (await user.comparePassword(password)) {
            console.log('✅ Login Success:', email);
            
            // 🛡️ Auto-promote owner to admin on login if not already
            if (email.toLowerCase() === 'vanshbansal99@gmail.com' && user.role !== 'admin') {
                user.role = 'admin';
                await user.save();
                console.log('👑 Owner auto-promoted to admin on login');
            }

            res.json({
                _id: user._id,
                name: user.name,
                email: user.email,
                role: user.role,
                token: generateToken(user._id)
            });
        } else {
            console.log('⚠️ Login Failed: Invalid password');
            res.status(401).json({ message: 'Invalid password. Please try again.' });
        }
    } catch (error) {
        console.error('❌ Login Error:', error);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get user profile
// @route   GET /api/auth/profile
exports.getUserProfile = async (req, res) => {
    const user = await User.findById(req.user._id);
    if (user) {
        res.json({
            _id: user._id,
            name: user.name,
            email: user.email,
            role: user.role,
            address: user.address,
            phone: user.phone
        });
    } else {
        res.status(404).json({ message: 'User not found' });
    }
};
