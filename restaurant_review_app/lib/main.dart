import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ⬅️ thêm
import 'firebase_options.dart'; // tạo bằng FlutterFire CLI
import 'ui/auth/sign_in_screen.dart';
import 'ui/restaurants/restaurant_list_screen.dart';
import 'services/fcm_service.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Xử lý thông báo khi app ở background (nếu cần)
}

/// Seed dữ liệu mẫu nếu collection `restaurants` đang trống.
/// Gồm 3 nhà hàng + ảnh minh hoạ, avgRating = 0.0
Future<void> _seedRestaurantsIfEmpty() async {
  final db = FirebaseFirestore.instance;
  final snap = await db.collection('restaurants').limit(1).get();
  if (snap.docs.isNotEmpty) return; // đã có data -> bỏ qua

  final sample = [
    {
      'name': 'Nhà hàng Sakura',
      'photoUrl': 'https://picsum.photos/seed/sakura/640/360',
      'avgRating': 0.0,
    },
    {
      'name': 'Bún Chả Hà Nội',
      'photoUrl': 'https://picsum.photos/seed/buncha/640/360',
      'avgRating': 0.0,
    },
    {
      'name': 'Pizza TinhJ',
      'photoUrl': 'https://picsum.photos/seed/pizza/640/360',
      'avgRating': 0.0,
    },
  ];

  final batch = db.batch();
  for (final r in sample) {
    final ref = db.collection('restaurants').doc();
    batch.set(ref, r);
  }
  await batch.commit();
  // (Tuỳ chọn) có thể tạo 1 review mẫu cho phần tử đầu tiên:
  final first = await db.collection('restaurants').limit(1).get();
  if (first.docs.isNotEmpty) {
    await db
        .collection('restaurants')
        .doc(first.docs.first.id)
        .collection('reviews')
        .add({
      'userId': 'seed-user',
      'content': 'Món ăn ngon, phục vụ nhiệt tình!',
      'rating': 5,
      'imageUrl': null,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
  // cập nhật avgRating đơn giản
  final all = await db.collection('restaurants').get();
  for (final d in all.docs) {
    final reviews = await db
        .collection('restaurants')
        .doc(d.id)
        .collection('reviews')
        .get();
    if (reviews.docs.isNotEmpty) {
      final ratings =
          reviews.docs.map((e) => (e['rating'] as num).toDouble()).toList();
      final avg = ratings.reduce((a, b) => a + b) / ratings.length;
      await db
          .collection('restaurants')
          .doc(d.id)
          .update({'avgRating': double.parse(avg.toStringAsFixed(1))});
    }
  }
  // Log cho bạn biết đã seed xong
  // ignore: avoid_print
  print('✅ Đã seed dữ liệu mẫu cho restaurants.');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Cách 1 (khuyên dùng): dùng firebase_options.dart được tạo bởi FlutterFire CLI
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {
    // Cách 2: fallback nếu chỉ có google-services.json (Android) / plist (iOS)
    await Firebase.initializeApp();
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FcmService.instance.init(); // xin quyền, subscribe topic

  // ⬇️ Seed dữ liệu mẫu (chỉ khi trống)
  await _seedRestaurantsIfEmpty();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Đánh giá Nhà hàng',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const RestaurantListScreen(),
      routes: {
        SignInScreen.routeName: (_) => const SignInScreen(),
      },
    );
  }
}
