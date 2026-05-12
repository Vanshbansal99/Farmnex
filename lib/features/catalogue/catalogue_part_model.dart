/// A data model representing a clickable spare part hotspot on the catalogue image.
class CataloguePart {
  final String id;
  final String name;
  final String partNumber;
  final double price;
  final String description;
  final String category;
  /// Position as fraction of the container (0.0 - 1.0)
  final double xFraction;
  final double yFraction;

  const CataloguePart({
    required this.id,
    required this.name,
    required this.partNumber,
    required this.price,
    required this.description,
    required this.category,
    required this.xFraction,
    required this.yFraction,
  });

  factory CataloguePart.fromJson(Map<String, dynamic> map) {
    return CataloguePart(
      id: map['_id'] ?? map['id'] ?? '',
      name: map['name'] ?? '',
      partNumber: map['partNumber'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      description: map['description'] ?? '',
      category: map['category'] ?? 'General',
      xFraction: (map['xFraction'] ?? 0).toDouble(),
      yFraction: (map['yFraction'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'partNumber': partNumber,
      'price': price,
      'description': description,
      'category': category,
      'xFraction': xFraction,
      'yFraction': yFraction,
    };
  }
}

/// A model representing a catalogue which contains an image and a list of parts.
class Catalogue {
  final String id;
  final String name;
  final String imageUrl;
  final List<CataloguePart> parts;

  const Catalogue({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.parts,
  });

  factory Catalogue.fromJson(Map<String, dynamic> json) {
    var partsList = json['parts'] as List? ?? [];
    List<CataloguePart> parts = partsList.map((i) => CataloguePart.fromJson(i)).toList();
    String imageUrl = json['imageUrl'] ?? '';
    if (imageUrl.startsWith('/uploads')) {
      // We don't have direct access to ApiConstants here, but we can assume relative path
      // The screen usually handles the full URL, but let's be safe and just pass it through
      // as the screen in catalogue_screen.dart already handles serverUrl prepending.
    }
    
    return Catalogue(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: imageUrl,
      parts: parts,
    );
  }
}


