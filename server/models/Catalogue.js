const mongoose = require('mongoose');

const cataloguePartSchema = new mongoose.Schema({
    partId: { type: String, required: false },
    name: { type: String, required: true },
    partNumber: { type: String, required: true },
    price: { type: Number, required: true },
    description: { type: String, required: true },
    xFraction: { type: Number, required: true },
    yFraction: { type: Number, required: true },
});

const catalogueSchema = new mongoose.Schema({
    name: { type: String, required: true },
    imageUrl: { type: String, required: true },
    parts: [cataloguePartSchema],
    createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Catalogue', catalogueSchema);
