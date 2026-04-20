class Place {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double rating;
  final String category;

  Place({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.category,
  });
}

final List<Place> demoPlaces = [
  Place(
    id: '1',
    name: 'Parque de la Caña',
    description: 'Un parque recreativo tradicional con piscinas y atracciones.',
    imageUrl: 'https://via.placeholder.com/400x200?text=Parque+de+la+Caña',
    rating: 4.5,
    category: 'Recreación',
  ),
  Place(
    id: '2',
    name: 'Cristo Rey',
    description: 'Monumento emblemático con una vista panorámica de la ciudad.',
    imageUrl: 'https://via.placeholder.com/400x200?text=Cristo+Rey',
    rating: 4.8,
    category: 'Turismo',
  ),
  Place(
    id: '3',
    name: 'Bulevar del Río',
    description: 'Espacio peatonal ideal para caminar y disfrutar de la brisa.',
    imageUrl: 'https://via.placeholder.com/400x200?text=Bulevar+del+Río',
    rating: 4.7,
    category: 'Cultura',
  ),
];
