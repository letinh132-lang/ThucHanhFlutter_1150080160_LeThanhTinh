import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/restaurant.dart';
import '../../data/models/review.dart';
import '../../services/storage_service.dart';
import '../../repositories/restaurant_repository.dart';

class AddReviewBottomSheet extends StatefulWidget {
  final Restaurant restaurant;
  const AddReviewBottomSheet({super.key, required this.restaurant});

  @override
  State<AddReviewBottomSheet> createState() => _AddReviewBottomSheetState();
}

class _AddReviewBottomSheetState extends State<AddReviewBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _contentCtl = TextEditingController();
  int _rating = 5;
  File? _image;
  XFile? _imageFile; // Cho web
  bool _loading = false;

  @override
  void dispose() {
    _contentCtl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    // Hiển thị dialog chọn Camera hoặc Thư viện
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Chọn nguồn ảnh',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading:
                  const Icon(Icons.camera_alt, color: Colors.blue, size: 32),
              title: const Text('Chụp ảnh', style: TextStyle(fontSize: 16)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library,
                  color: Colors.green, size: 32),
              title: const Text('Chọn từ thư viện',
                  style: TextStyle(fontSize: 16)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final x = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 80,
    );

    if (x != null) {
      setState(() {
        _imageFile = x;
        if (!kIsWeb) {
          _image = File(x.path);
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập.')),
      );
      return;
    }

    setState(() => _loading = true);

    String? imageUrl;
    bool imageUploadFailed = false;

    try {
      // Upload ảnh nếu có (với error handling)
      if (_imageFile != null) {
        try {
          final file = kIsWeb ? File(_imageFile!.path) : _image!;
          imageUrl = await StorageService.instance.uploadReviewImage(
            file,
            widget.restaurant.id,
            user.uid,
          );
        } catch (imageError) {
          print('Image upload failed: $imageError');
          imageUploadFailed = true;

          // Hỏi user có muốn tiếp tục không
          final shouldContinue = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Lỗi upload ảnh'),
              content: Text(
                'Không thể upload ảnh: ${imageError.toString()}\n\n'
                'Bạn có muốn gửi đánh giá KHÔNG có ảnh không?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Gửi không có ảnh'),
                ),
              ],
            ),
          );

          if (shouldContinue != true) {
            setState(() => _loading = false);
            return;
          }
        }
      }

      // Tạo review (với hoặc không có ảnh)
      final review = Review(
        id: '',
        userId: user.uid,
        content: _contentCtl.text.trim(),
        rating: _rating,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      // Lưu review vào Firestore
      await RestaurantRepository.instance.addReview(
        restaurantId: widget.restaurant.id,
        review: review,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    imageUploadFailed
                        ? 'Đã gửi đánh giá (không có ảnh)!'
                        : 'Đã gửi đánh giá!',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 20),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Đánh giá – ${widget.restaurant.name}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Rating selector
              const Text(
                'Điểm đánh giá',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final starValue = i + 1;
                    return IconButton(
                      iconSize: 40,
                      onPressed: () => setState(() => _rating = starValue),
                      icon: Icon(
                        starValue <= _rating ? Icons.star : Icons.star_border,
                        color:
                            starValue <= _rating ? Colors.amber : Colors.grey,
                      ),
                    );
                  }),
                ),
              ),
              Center(
                child: Text(
                  '$_rating sao',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Content input
              const Text(
                'Nội dung đánh giá',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentCtl,
                decoration: InputDecoration(
                  hintText: 'Chia sẻ trải nghiệm của bạn...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                maxLines: 4,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Vui lòng nhập nội dung'
                    : null,
              ),
              const SizedBox(height: 16),

              // Image picker
              const Text(
                'Hình ảnh (tùy chọn)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _loading ? null : _pickImage,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[50],
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            children: [
                              // Hiển thị ảnh cho cả web và mobile
                              if (kIsWeb)
                                FutureBuilder<dynamic>(
                                  future: _imageFile!.readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Image.memory(
                                        snapshot.data,
                                        width: double.infinity,
                                        height: 160,
                                        fit: BoxFit.cover,
                                      );
                                    }
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const CircularProgressIndicator(),
                                          const SizedBox(height: 8),
                                          Text('Đang tải ảnh...',
                                              style: TextStyle(
                                                  color: Colors.grey[600])),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              else if (_image != null)
                                Image.file(
                                  _image!,
                                  width: double.infinity,
                                  height: 160,
                                  fit: BoxFit.cover,
                                ),
                              // Nút xóa ảnh
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Material(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () => setState(() {
                                      _image = null;
                                      _imageFile = null;
                                    }),
                                    child: const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Icon(Icons.close,
                                          color: Colors.white, size: 20),
                                    ),
                                  ),
                                ),
                              ),
                              // Label góc trái
                              Positioned(
                                bottom: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    '✓ Đã chọn ảnh',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate,
                                size: 56, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'Chụp ảnh hoặc chọn từ thư viện',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt,
                                    size: 18, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Text('Camera',
                                    style: TextStyle(
                                        color: Colors.grey[500], fontSize: 13)),
                                const SizedBox(width: 16),
                                Icon(Icons.photo_library,
                                    size: 18, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Text('Thư viện',
                                    style: TextStyle(
                                        color: Colors.grey[500], fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(_loading ? 'Đang gửi...' : 'Gửi đánh giá'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
