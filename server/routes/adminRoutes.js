const express = require('express');
const router = express.Router();
const { getDashboardStats, getRevenueAnalytics } = require('../controllers/adminController');
const { protect, admin } = require('../middleware/authMiddleware');

router.get('/stats', protect, admin, getDashboardStats);
router.get('/revenue', protect, admin, getRevenueAnalytics);

module.exports = router;
