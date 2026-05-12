const Product = require('../models/Product');
const fs = require('fs');
const path = require('path');

const MOCK_DB_PATH = path.join(__dirname, '../data/products.json');

// Ensure directory exists
const ensureDirectoryExistence = (filePath) => {
    const dirname = path.dirname(filePath);
    if (fs.existsSync(dirname)) return true;
    fs.mkdirSync(dirname, { recursive: true });
};

// Helper to read from mock file
const readMockProducts = () => {
    try {
        if (!fs.existsSync(MOCK_DB_PATH)) {
            // Initial mock data if file doesn't exist
            const initialData = [
                { _id: '1', name: 'Engine Piston Kit', category: 'Engine', price: 4299.0, stock: 15, description: 'High-performance piston kit for Mahindra tractors.', brand: 'Mahindra', images: [] },
                { _id: '2', name: 'Hydraulic Pump', category: 'Hydraulic', price: 8500.0, stock: 8, description: 'Heavy-duty hydraulic pump.', brand: 'John Deere', images: [] },
                { _id: '3', name: 'Oil Filter', category: 'Filters', price: 450.0, stock: 50, description: 'Premium oil filter.', brand: 'Generic', images: [] },
                { _id: '4', name: 'Transmission Gear', category: 'Transmission', price: 12000.0, stock: 5, description: 'Precision gear for smooth shifting.', brand: 'Sonalika', images: [] },
            ];
            ensureDirectoryExistence(MOCK_DB_PATH);
            fs.writeFileSync(MOCK_DB_PATH, JSON.stringify(initialData, null, 2));
            return initialData;
        }
        const data = fs.readFileSync(MOCK_DB_PATH, 'utf8');
        return JSON.parse(data);
    } catch (e) {
        return [];
    }
};

// @desc    Get all products
// @route   GET /api/products
exports.getProducts = async (req, res) => {
    try {
        const { category, brand, search, sort } = req.query;
        
        let products;
        try {
            let query = {};
            if (category) query.category = category;
            if (brand) query.brand = brand;
            if (search) {
                query.name = { $regex: search, $options: 'i' };
            }

            let productsQuery = Product.find(query);
            if (sort) {
                const sortBy = sort.split(',').join(' ');
                productsQuery = productsQuery.sort(sortBy);
            } else {
                productsQuery = productsQuery.sort('-createdAt');
            }
            products = await productsQuery;
        } catch (dbError) {
            console.log('⚠️ MongoDB down, falling back to JSON storage for GET Products');
            products = readMockProducts();
            
            // Manual filter for mock data
            if (category) products = products.filter(p => p.category === category);
            if (brand) products = products.filter(p => p.brand === brand);
            if (search) {
                const searchLower = search.toLowerCase();
                products = products.filter(p => p.name.toLowerCase().includes(searchLower));
            }
        }
        
        res.json(products);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get single product
// @route   GET /api/products/:id
exports.getProductById = async (req, res) => {
    try {
        try {
            const product = await Product.findById(req.params.id);
            if (product) {
                return res.json(product);
            }
        } catch (dbError) {
            const products = readMockProducts();
            const product = products.find(p => p._id === req.params.id);
            if (product) return res.json(product);
        }
        res.status(404).json({ message: 'Product not found' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Create a product (Admin)
// @route   POST /api/products
exports.createProduct = async (req, res) => {
    try {
        const productData = { ...req.body };
        // Convert isFeatured from string "true"/"false" to boolean
        productData.isFeatured = productData.isFeatured === 'true' || productData.isFeatured === true;
        
        if (req.file) {
            const imagePath = req.file.path.startsWith('http') 
                ? req.file.path 
                : `/uploads/products/${req.file.filename}`;
            productData.images = [imagePath];
        }

        try {
            const product = new Product(productData);
            const createdProduct = await product.save();
            res.status(201).json(createdProduct);
        } catch (dbError) {
            const products = readMockProducts();
            const newProduct = { ...productData, _id: Date.now().toString(), createdAt: new Date() };
            products.unshift(newProduct);
            fs.writeFileSync(MOCK_DB_PATH, JSON.stringify(products, null, 2));
            res.status(201).json(newProduct);
        }
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
};

// @desc    Update a product (Admin)
// @route   PUT /api/products/:id
exports.updateProduct = async (req, res) => {
    try {
        const updateData = { ...req.body };
        if (updateData.isFeatured !== undefined) {
            updateData.isFeatured = updateData.isFeatured === 'true' || updateData.isFeatured === true;
        }
        
        if (req.file) {
            const imagePath = req.file.path.startsWith('http') 
                ? req.file.path 
                : `/uploads/products/${req.file.filename}`;
            updateData.images = [imagePath];
        }

        try {
            const product = await Product.findByIdAndUpdate(req.params.id, updateData, { new: true });
            if (product) return res.json(product);
        } catch (dbError) {
            let products = readMockProducts();
            const index = products.findIndex(p => p._id === req.params.id);
            if (index !== -1) {
                products[index] = { ...products[index], ...updateData };
                fs.writeFileSync(MOCK_DB_PATH, JSON.stringify(products, null, 2));
                return res.json(products[index]);
            }
        }
        res.status(404).json({ message: 'Product not found' });
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
};

// @desc    Delete a product (Admin)
// @route   DELETE /api/products/:id
exports.deleteProduct = async (req, res) => {
    try {
        try {
            const product = await Product.findByIdAndDelete(req.params.id);
            if (product) return res.json({ message: 'Product removed' });
        } catch (dbError) {
            let products = readMockProducts();
            const initialLength = products.length;
            // Robust filtering for both _id and id formats
            products = products.filter(p => {
                const pId = (p._id || p.id || '').toString();
                return pId !== req.params.id;
            });

            if (products.length < initialLength) {
                fs.writeFileSync(MOCK_DB_PATH, JSON.stringify(products, null, 2));
                return res.json({ message: 'Product removed' });
            }
        }
        res.status(404).json({ message: 'Product not found' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};
