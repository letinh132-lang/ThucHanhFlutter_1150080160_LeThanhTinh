import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/reader_controls.dart';

class ReaderScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const ReaderScreen({super.key, required this.onToggleTheme});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final PageController _pageController = PageController();
  String _text = '';
  List<String> _pages = [];
  double _fontSize = 18;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _restoreSettings().then((_) => _loadBook());
  }

  Future<void> _restoreSettings() async {
    final sp = await SharedPreferences.getInstance();
    _fontSize = sp.getDouble('fontSize') ?? 18;
    _currentPage = sp.getInt('lastPage') ?? 0;
    setState((){});
  }

  Future<void> _persistSettings() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setDouble('fontSize', _fontSize);
    await sp.setInt('lastPage', _currentPage);
  }

  Future<void> _loadBook() async {
    final content = await rootBundle.loadString('assets/book.txt');
    setState(() => _text = content);
    _paginate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentPage < _pages.length) {
        _pageController.jumpToPage(_currentPage);
      }
    });
  }

  void _paginate() {
    // Ước lượng độ dài mỗi trang theo fontSize để dễ hiểu.
    final approxPerPage = 1200 * (18 / _fontSize);
    final chunks = <String>[];
    int i = 0;
    while (i < _text.length) {
      final end = (_text.length - i > approxPerPage) ? i + approxPerPage.toInt() : _text.length;
      chunks.add(_text.substring(i, end));
      i = end;
    }
    setState(() => _pages = chunks);
  }

  void _changeFont(double v) {
    setState(() {
      _fontSize = v;
      _paginate();
    });
    _persistSettings();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sách điện tử'),
        actions: [
          IconButton(
            tooltip: 'Chế độ sáng/tối',
            onPressed: widget.onToggleTheme,
            icon: const Icon(Icons.brightness_6),
          ),
        ],
      ),
      body: _pages.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Thanh tiêu đề + indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Text('Đang đọc', style: TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text('${_currentPage + 1}/${_pages.length}'),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (idx) {
                      setState(() => _currentPage = idx);
                      _persistSettings();
                    },
                    itemCount: _pages.length,
                    itemBuilder: (ctx, i) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            )
                          ],
                        ),
                        child: CustomPaint(
                          painter: _PagePainter(
                            _pages[i],
                            _fontSize,
                            Theme.of(context).textTheme.bodyLarge!.color ?? Colors.black,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Dots indicator đơn giản
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _DotsIndicator(current: _currentPage, total: _pages.length),
                ),
              ],
            ),
      bottomNavigationBar: ReaderControls(
        onFontTap: () async {
          // Mở bottom sheet chỉnh font
          final newSize = await showModalBottomSheet<double>(
            context: context,
            showDragHandle: true,
            builder: (ctx) {
              double temp = _fontSize;
              return StatefulBuilder(
                builder: (ctx, setStateSheet) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Cỡ chữ', style: TextStyle(fontWeight: FontWeight.w600)),
                      Slider(
                        min: 12,
                        max: 32,
                        divisions: 10,
                        value: temp,
                        label: temp.toStringAsFixed(0),
                        onChanged: (v) => setStateSheet(() => temp = v),
                      ),
                      FilledButton.icon(
                        onPressed: () => Navigator.pop(ctx, temp),
                        icon: const Icon(Icons.check),
                        label: const Text('Áp dụng'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
          if (newSize != null) _changeFont(newSize);
        },
        onPrev: () {
          if (_currentPage > 0) {
            _pageController.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
          }
        },
        onNext: () {
          if (_currentPage < _pages.length - 1) {
            _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
          }
        },
      ),
    );
  }
}

// Painter vẽ trang đọc
class _PagePainter extends CustomPainter {
  final String text;
  final double fontSize;
  final Color color;
  _PagePainter(this.text, this.fontSize, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 20.0;
    final maxWidth = size.width - padding * 2;
    final topLeft = Offset(padding, padding);

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, color: color, height: 1.5),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 9999,
    );
    tp.layout(maxWidth: maxWidth);
    tp.paint(canvas, topLeft);

    // Viền trang
    final rect = Rect.fromLTWH(10, 10, size.width - 20, size.height - 20);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(14)), paint);
  }

  @override
  bool shouldRepaint(covariant _PagePainter old) =>
      old.text != text || old.fontSize != fontSize || old.color != color;
}

// Dots indicator đơn giản
class _DotsIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _DotsIndicator({super.key, required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final dots = List.generate(total.clamp(0, 6), (i) {
      final active = i == (current % (total.clamp(1, 999999)));
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: active ? 12 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: active ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
          borderRadius: BorderRadius.circular(999),
        ),
      );
    });
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: dots);
  }
}
