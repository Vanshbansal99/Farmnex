const Catalogue = require('../models/Catalogue');
const Product = require('../models/Product');
const fs = require('fs');
const path = require('path');

const MOCK_DB_PATH = path.join(__dirname, '../data/catalogues.json');

// Ensure directory exists
const ensureDirectoryExistence = (filePath) => {
    const dirname = path.dirname(filePath);
    if (fs.existsSync(dirname)) return true;
    fs.mkdirSync(dirname, { recursive: true });
};

// Helper to read from mock file
const readMockCatalogues = () => {
    try {
        if (!fs.existsSync(MOCK_DB_PATH)) return [];
        const data = fs.readFileSync(MOCK_DB_PATH, 'utf8');
        return JSON.parse(data);
    } catch (e) {
        return [];
    }
};

// Helper to write to mock file
const writeMockCatalogue = (catalogue) => {
    ensureDirectoryExistence(MOCK_DB_PATH);
    const catalogues = readMockCatalogues();
    catalogues.unshift(catalogue);
    fs.writeFileSync(MOCK_DB_PATH, JSON.stringify(catalogues, null, 2));
};

// @desc    Get all catalogues
// @route   GET /api/catalogues
// @access  Public
const getCatalogues = async (req, res) => {
    try {
        const catalogues = await Catalogue.find({}).sort({ createdAt: -1 });
        res.json(catalogues);
    } catch (error) {
        console.log('⚠️ MongoDB down, falling back to JSON storage for GET');
        res.json(readMockCatalogues());
    }
};

// @desc    Create a catalogue
// @route   POST /api/catalogues
// @access  Private/Admin
const createCatalogue = async (req, res) => {
    try {
        const { name, parts } = req.body;
        
        if (!req.file) {
            return res.status(400).json({ message: 'Please upload an image' });
        }

        const imageUrl = req.file.path.startsWith('http') 
            ? req.file.path 
            : `/uploads/catalogues/${req.file.filename}`;

        let parsedParts = [];
        if (parts) {
            try {
                const rawParts = typeof parts === 'string' ? JSON.parse(parts) : parts;
                // Map 'id' from frontend to 'partId' for MongoDB schema compatibility
                parsedParts = rawParts.map(p => ({
                    ...p,
                    partId: p.id || Date.now().toString()
                }));
            } catch (e) {
                return res.status(400).json({ message: 'Invalid parts format' });
            }
        }

        const catalogueData = {
            name,
            imageUrl,
            parts: parsedParts,
            createdAt: new Date()
        };

        try {
            const catalogue = new Catalogue(catalogueData);
            const createdCatalogue = await catalogue.save();
            
            // SYNC: Create products for each part if they don't exist
            for (const part of parsedParts) {
                const productExists = await Product.findOne({ name: part.name });
                if (!productExists) {
                    await Product.create({
                        name: part.name,
                        partNumber: part.partNumber,
                        description: part.description,
                        price: part.price,
                        category: part.category || 'General',
                        brand: 'FarmNex',
                        stock: 10,
                        isFeatured: true, // Mark as featured for home screen visibility
                        images: [imageUrl]
                    });
                }
            }

            res.status(201).json(createdCatalogue);
        } catch (dbError) {
            console.error('❌ MongoDB Catalogue Save Error:', dbError);
            console.log('⚠️ MongoDB error, falling back to JSON storage for POST');
            const mockCatalogue = { ...catalogueData, _id: Date.now().toString() };
            writeMockCatalogue(mockCatalogue);
            
            // SYNC: Create mock products in products.json
            try {
                const PRODUCTS_MOCK_PATH = path.join(__dirname, '../data/products.json');
                let mockProducts = [];
                if (fs.existsSync(PRODUCTS_MOCK_PATH)) {
                    mockProducts = JSON.parse(fs.readFileSync(PRODUCTS_MOCK_PATH, 'utf8'));
                }

                for (const part of parsedParts) {
                    if (!mockProducts.some(p => p.name === part.name)) {
                        mockProducts.unshift({
                            _id: Date.now().toString() + Math.random().toString(36).substr(2, 5),
                            name: part.name,
                            partNumber: part.partNumber,
                            description: part.description,
                            price: part.price,
                            category: part.category || 'General',
                            brand: 'FarmNex',
                            stock: 10,
                            isFeatured: true,
                            images: [imageUrl],
                            createdAt: new Date()
                        });
                    }
                }
                fs.writeFileSync(PRODUCTS_MOCK_PATH, JSON.stringify(mockProducts, null, 2));
            } catch (e) {
                console.error('Failed to sync mock products:', e);
            }
            
            res.status(201).json(mockCatalogue);
        }
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server Error' });
    }
};

// @desc    Delete a catalogue (Admin)
// @route   DELETE /api/catalogues/:id
const deleteCatalogue = async (req, res) => {
    try {
        try {
            const catalogue = await Catalogue.findByIdAndDelete(req.params.id);
            if (catalogue) return res.json({ message: 'Catalogue removed' });
        } catch (dbError) {
            let catalogues = readMockCatalogues();
            const initialLength = catalogues.length;
            // Correctly exclude the catalogue being deleted
            catalogues = catalogues.filter(c => {
                const cId = (c._id || c.id || '').toString();
                return cId !== req.params.id;
            });
            
            if (catalogues.length < initialLength) {
                fs.writeFileSync(MOCK_DB_PATH, JSON.stringify(catalogues, null, 2));
                return res.json({ message: 'Catalogue removed' });
            }
        }
        res.status(404).json({ message: 'Catalogue not found' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: error.message });
    }
};

module.exports = {
    getCatalogues,
    createCatalogue,
    deleteCatalogue
};
