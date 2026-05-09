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
