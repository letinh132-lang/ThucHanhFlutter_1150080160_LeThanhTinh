import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/restaurant.dart';
import '../data/models/review.dart';

class RestaurantRepository {
  RestaurantRepository._();
  static final instance = RestaurantRepository._();
  final _db = FirebaseFirestore.instance;

  Stream<List<Restaurant>> watchRestaurants() {
    return _db.collection('restaurants').orderBy('name').snapshots().map(
          (snap) =>
              snap.docs.map((d) => Restaurant.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> addReview({
    required String restaurantId,
    required Review review,
  }) async {
    // Lưu review vào Firestore
    final ref = _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('reviews')
        .doc();
    await ref.set(review.toMap());

    // Cập nhật avgRating
    final reviewsSnap = await _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('reviews')
        .get();

    if (reviewsSnap.docs.isNotEmpty) {
      final ratings =
          reviewsSnap.docs.map((d) => (d['rating'] as num).toDouble()).toList();
      final avg = ratings.reduce((a, b) => a + b) / ratings.length;
      await _db
          .collection('restaurants')
          .doc(restaurantId)
          .update({'avgRating': double.parse(avg.toStringAsFixed(1))});
    }

    // Gửi thông báo FCM về review mới
    // Trong production, bạn nên gọi Cloud Function để gửi FCM
    // Ở đây demo bằng cách log (cần setup FCM server để gửi thật)
    try {
      final restaurantDoc =
          await _db.collection('restaurants').doc(restaurantId).get();
      final restaurantName = restaurantDoc.data()?['name'] ?? 'Nhà hàng';

      // Log thông báo (trong thực tế cần gọi FCM API từ server)
      // ignore: avoid_print
      print('📢 FCM: New review for $restaurantName - ${review.rating} stars');

      // Lưu notification vào Firestore để admin/user khác có thể xem
      await _db.collection('notifications').add({
        'restaurantId': restaurantId,
        'restaurantName': restaurantName,
        'userId': review.userId,
        'rating': review.rating,
        'content': review.content,
        'createdAt': DateTime.now().toIso8601String(),
        'type': 'new_review',
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error sending notification: $e');
    }
  }
}
