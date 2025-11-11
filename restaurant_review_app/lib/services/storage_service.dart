import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService._();
  static final instance = StorageService._();
  final _storage = FirebaseStorage.instance;

  Future<String?> uploadReviewImage(
      File file, String restaurantId, String uid) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref =
          _storage.ref().child('reviews/$restaurantId/${uid}_$timestamp.jpg');

      // Thêm metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': uid,
          'restaurantId': restaurantId,
        },
      );

      // Upload với timeout
      final task = ref.putFile(file, metadata);

      // Đợi upload hoàn thành
      final snapshot = await task.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          task.cancel();
          throw Exception('Upload timeout - vui lòng thử lại');
        },
      );

      // Lấy download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      print('Firebase Storage Error: ${e.code} - ${e.message}');

      // Xử lý các lỗi cụ thể
      if (e.code == 'unauthorized' || e.code == 'permission-denied') {
        throw Exception(
            'Không có quyền upload ảnh. Vui lòng kiểm tra Storage Rules.');
      } else if (e.code == 'canceled') {
        throw Exception('Upload bị hủy - vui lòng thử lại');
      } else if (e.code == 'unknown') {
        throw Exception('Lỗi kết nối - vui lòng kiểm tra internet');
      }

      throw Exception('Lỗi upload ảnh: ${e.message}');
    } catch (e) {
      print('Upload Error: $e');
      throw Exception('Lỗi upload ảnh: $e');
    }
  }
}
