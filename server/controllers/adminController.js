const Order = require('../models/Order');
const Product = require('../models/Product');
const User = require('../models/User');

// @desc    Get admin dashboard stats
// @route   GET /api/admin/stats
exports.getDashboardStats = async (req, res) => {
    try {
        const totalOrders = await Order.countDocuments();
        const totalProducts = await Product.countDocuments();
        const totalUsers = await User.countDocuments();
        
        const orders = await Order.find({});
        const totalRevenue = orders.reduce((acc, item) => acc + item.totalPrice, 0);

        const recentOrders = await Order.find({})
            .populate('user', 'name')
            .sort('-createdAt')
            .limit(5);

        res.json({
            totalOrders,
            totalProducts,
            totalUsers,
            totalRevenue,
            recentOrders
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get revenue analytics (monthly)
// @route   GET /api/admin/revenue
exports.getRevenueAnalytics = async (req, res) => {
    try {
        const analytics = await Order.aggregate([
            {
                $group: {
                    _id: { $month: "$createdAt" },
                    totalRevenue: { $sum: "$totalPrice" },
                    count: { $sum: 1 }
                }
            },
            { $sort: { "_id": 1 } }
        ]);
        res.json(analytics);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get all users
// @route   GET /api/admin/users
exports.getAllUsers = async (req, res) => {
    try {
        const users = await User.find({}).select('-password').sort('-createdAt');
        res.json(users);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Delete user
// @route   DELETE /api/admin/users/:id
exports.deleteUser = async (req, res) => {
    try {
        const user = await User.findById(req.params.id);
        if (user) {
            if (user.role === 'admin') {
                return res.status(400).json({ message: 'Cannot delete admin users' });
            }
            await user.deleteOne();
            res.json({ message: 'User removed successfully' });
        } else {
            res.status(404).json({ message: 'User not found' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};
