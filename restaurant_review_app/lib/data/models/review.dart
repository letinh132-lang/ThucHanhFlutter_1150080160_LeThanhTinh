class Review {
  final String id;
  final String userId;
  final String content;
  final int rating; // 1..5
  final String? imageUrl;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.userId,
    required this.content,
    required this.rating,
    required this.imageUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'content': content,
        'rating': rating,
        'imageUrl': imageUrl,
        'createdAt': createdAt.toIso8601String(),
      };
}
