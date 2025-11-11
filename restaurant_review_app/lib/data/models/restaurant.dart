class Restaurant {
  final String id;
  final String name;
  final String? photoUrl;
  final double avgRating;
  Restaurant({required this.id, required this.name, this.photoUrl, required this.avgRating});

  factory Restaurant.fromMap(String id, Map<String, dynamic> map) {
    return Restaurant(
      id: id,
      name: map['name'] ?? 'Unknown',
      photoUrl: map['photoUrl'],
      avgRating: (map['avgRating'] ?? 0).toDouble(),
    );
  }
}
