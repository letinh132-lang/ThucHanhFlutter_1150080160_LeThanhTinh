import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Thông báo')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              const Text('Vui lòng đăng nhập để xem thông báo'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử đánh giá mới'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getAllRecentReviews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Lỗi: ${snapshot.error}'),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 100, color: Colors.grey[300]),
                  const SizedBox(height: 24),
                  Text(
                    'Chưa có đánh giá mới nào',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lịch sử 20 đánh giá gần nhất sẽ hiển thị ở đây',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final restaurantName =
                  notification['restaurantName'] as String? ?? 'Nhà hàng';
              final rating = notification['rating'] as int? ?? 5;
              final content = notification['content'] as String? ?? '';
              final createdAt = notification['createdAt'] as String? ?? '';
              final userName =
                  notification['userName'] as String? ?? 'Người dùng';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.rate_review,
                      color: Colors.orange.shade700,
                      size: 28,
                    ),
                  ),
                  title: Text(
                    '✨ $userName đã đánh giá $restaurantName',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (i) => Icon(
                              i < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$rating sao',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        content.length > 100
                            ? '${content.substring(0, 100)}...'
                            : content,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatDate(createdAt),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Lấy 20 review gần nhất từ tất cả nhà hàng
  Future<List<Map<String, dynamic>>> _getAllRecentReviews() async {
    try {
      final restaurants =
          await FirebaseFirestore.instance.collection('restaurants').get();

      final List<Map<String, dynamic>> allReviews = [];

      for (final restaurantDoc in restaurants.docs) {
        final reviewsSnap = await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(restaurantDoc.id)
            .collection('reviews')
            .orderBy('createdAt', descending: true)
            .limit(5)
            .get();

        for (final reviewDoc in reviewsSnap.docs) {
          final reviewData = reviewDoc.data();
          allReviews.add({
            'restaurantName': restaurantDoc['name'] ?? 'Nhà hàng',
            'rating': reviewData['rating'] ?? 5,
            'content': reviewData['content'] ?? '',
            'createdAt': reviewData['createdAt'] ?? '',
            'userName': reviewData['userId']?.substring(0, 8) ?? 'User',
          });
        }
      }

      // Sắp xếp và lấy 20 review mới nhất
      allReviews.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['createdAt'] as String);
          final dateB = DateTime.parse(b['createdAt'] as String);
          return dateB.compareTo(dateA);
        } catch (_) {
          return 0;
        }
      });

      return allReviews.take(20).toList();
    } catch (e) {
      return [];
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        if (diff.inHours == 0) {
          return '${diff.inMinutes} phút trước';
        }
        return '${diff.inHours} giờ trước';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} ngày trước';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (_) {
      return 'Vừa xong';
    }
  }
}
