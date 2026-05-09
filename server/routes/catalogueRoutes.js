const express = require('express');
const router = express.Router();
const { getCatalogues, createCatalogue } = require('../controllers/catalogueController');
const { protect, admin } = require('../middleware/authMiddleware');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Set up multer for catalogue image uploads
const storage = multer.diskStorage({
    destination(req, file, cb) {
        const dir = 'uploads/catalogues/';
        // Ensure directory exists
        if (!fs.existsSync(dir)){
            fs.mkdirSync(dir, { recursive: true });
        }
        cb(null, dir);
    },
    filename(req, file, cb) {
        cb(null, `${file.fieldname}-${Date.now()}${path.extname(file.originalname)}`);
    }
});

function checkFileType(file, cb) {
    const filetypes = /jpg|jpeg|png|webp/;
    const extname = filetypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = filetypes.test(file.mimetype);

    if (extname && mimetype) {
        return cb(null, true);
    } else {
        cb('Images only!');
    }
}

const upload = multer({
    storage,
    fileFilter: function (req, file, cb) {
        checkFileType(file, cb);
    }
});

router.route('/')
    .get(getCatalogues)
    .post(protect, admin, upload.single('image'), createCatalogue);

module.exports = router;
