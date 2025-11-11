import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  List<Map<String, dynamic>> _allReviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);

    try {
      final restaurants =
          await FirebaseFirestore.instance.collection('restaurants').get();

      final List<Map<String, dynamic>> allReviews = [];

      for (final restaurantDoc in restaurants.docs) {
        final reviewsSnap = await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(restaurantDoc.id)
            .collection('reviews')
            .where('userId', isEqualTo: user.uid)
            .get();

        for (final reviewDoc in reviewsSnap.docs) {
          allReviews.add({
            'restaurantId': restaurantDoc.id,
            'restaurantName': restaurantDoc['name'] ?? 'Nhà hàng',
            'restaurantPhoto': restaurantDoc['photoUrl'],
            'reviewId': reviewDoc.id,
            'review': reviewDoc.data(),
          });
        }
      }

      // Sắp xếp theo thời gian
      allReviews.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['review']['createdAt'] as String);
          final dateB = DateTime.parse(b['review']['createdAt'] as String);
          return dateB.compareTo(dateA);
        } catch (_) {
          return 0;
        }
      });

      setState(() {
        _allReviews = allReviews;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Đánh giá của tôi')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              const Text('Vui lòng đăng nhập để xem đánh giá của bạn'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đánh giá của tôi'),
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _allReviews.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rate_review_outlined,
                          size: 100, color: Colors.grey[300]),
                      const SizedBox(height: 24),
                      Text(
                        'Bạn chưa có đánh giá nào',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hãy bắt đầu đánh giá nhà hàng!',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReviews,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _allReviews.length,
                    itemBuilder: (context, index) {
                      final reviewData = _allReviews[index];
                      final review =
                          reviewData['review'] as Map<String, dynamic>;
                      final restaurantId = reviewData['restaurantId'] as String;
                      final restaurantName =
                          reviewData['restaurantName'] as String;
                      final restaurantPhoto =
                          reviewData['restaurantPhoto'] as String?;
                      final reviewId = reviewData['reviewId'] as String;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Restaurant info header
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.orange.shade50, Colors.white],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundImage: restaurantPhoto != null
                                        ? NetworkImage(restaurantPhoto)
                                        : null,
                                    child: restaurantPhoto == null
                                        ? const Icon(Icons.restaurant)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          restaurantName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          _formatDate(
                                              review['createdAt'] as String),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: List.generate(
                                      5,
                                      (i) => Icon(
                                        i < (review['rating'] as int)
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Review content
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    review['content'] as String,
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  if (review['imageUrl'] != null) ...[
                                    const SizedBox(height: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        review['imageUrl'] as String,
                                        width: double.infinity,
                                        height: 180,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          height: 180,
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.broken_image),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Action buttons
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Xóa đánh giá'),
                                          content: const Text(
                                            'Bạn có chắc muốn xóa đánh giá này?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text('Hủy'),
                                            ),
                                            FilledButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: const Text('Xóa'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        // Xóa review
                                        await FirebaseFirestore.instance
                                            .collection('restaurants')
                                            .doc(restaurantId)
                                            .collection('reviews')
                                            .doc(reviewId)
                                            .delete();

                                        // Cập nhật avgRating
                                        final reviewsSnap =
                                            await FirebaseFirestore.instance
                                                .collection('restaurants')
                                                .doc(restaurantId)
                                                .collection('reviews')
                                                .get();

                                        if (reviewsSnap.docs.isNotEmpty) {
                                          final ratings = reviewsSnap.docs
                                              .map((d) => (d['rating'] as num)
                                                  .toDouble())
                                              .toList();
                                          final avg =
                                              ratings.reduce((a, b) => a + b) /
                                                  ratings.length;
                                          await FirebaseFirestore.instance
                                              .collection('restaurants')
                                              .doc(restaurantId)
                                              .update({
                                            'avgRating': double.parse(
                                                avg.toStringAsFixed(1))
                                          });
                                        } else {
                                          await FirebaseFirestore.instance
                                              .collection('restaurants')
                                              .doc(restaurantId)
                                              .update({'avgRating': 0.0});
                                        }

                                        // Reload reviews
                                        await _loadReviews();

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text('Đã xóa đánh giá'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Xóa'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
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
