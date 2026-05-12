const express = require('express');
const router = express.Router();
const { getCatalogues, createCatalogue, deleteCatalogue } = require('../controllers/catalogueController');
const { protect, admin } = require('../middleware/authMiddleware');
const { upload: cloudinaryUpload } = require('../config/cloudinary');
const multer = require('multer');
const fs = require('fs');
const path = require('path');

// Hybrid Storage Strategy: Use Cloudinary if keys exist, else use Local Storage
let upload;
if (process.env.CLOUDINARY_CLOUD_NAME && process.env.CLOUDINARY_API_KEY) {
    upload = cloudinaryUpload;
} else {
    // Set up local multer for catalogue image uploads (Development Fallback)
    const storage = multer.diskStorage({
        destination(req, file, cb) {
            const dir = 'uploads/catalogues/';
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
    .get(getCatalogues)
    .post(protect, admin, upload.single('image'), createCatalogue);

router.route('/:id')
    .delete(protect, admin, deleteCatalogue);

module.exports = router;
