const express = require('express');
const router = express.Router();
const { getProducts, getProductById, createProduct, updateProduct, deleteProduct } = require('../controllers/productController');
const { protect, admin } = require('../middleware/authMiddleware');
const { upload: cloudinaryUpload } = require('../config/cloudinary');

// Hybrid Storage Strategy: Use Cloudinary if keys exist, else use Local Storage
let upload;
if (process.env.CLOUDINARY_CLOUD_NAME && process.env.CLOUDINARY_API_KEY) {
    upload = cloudinaryUpload;
} else {
    // Set up local multer for product image uploads (Development Fallback)
    const storage = multer.diskStorage({
        destination(req, file, cb) {
            const dir = 'uploads/products/';
            if (!fs.existsSync(dir)){
                fs.mkdirSync(dir, { recursive: true });
            }
            cb(null, dir);
        },
        filename(req, file, cb) {
            cb(null, `${file.fieldname}-${Date.now()}${path.extname(file.originalname)}`);
        }
    });

    upload = multer({
        storage,
        fileFilter: function (req, file, cb) {
            const filetypes = /jpg|jpeg|png|webp/;
            const extname = filetypes.test(path.extname(file.originalname).toLowerCase());
            const mimetype = filetypes.test(file.mimetype);
            if (extname && mimetype) {
                cb(null, true);
            } else {
                cb('Images only!');
            }
        }
    });
}

router.route('/')
    .get(getProducts)
    .post(protect, admin, upload.single('image'), createProduct);

router.route('/:id')
    .get(getProductById)
    .put(protect, admin, upload.single('image'), updateProduct)
    .delete(protect, admin, deleteProduct);

module.exports = router;
