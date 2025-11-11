import 'package:flutter/material.dart';

class ReaderControls extends StatelessWidget {
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onFontTap;
  const ReaderControls({
    super.key,
    required this.onPrev,
    required this.onNext,
    required this.onFontTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            _RoundIcon(
              icon: Icons.text_increase,
              tooltip: 'Cỡ chữ',
              onTap: onFontTap,
            ),
            const Spacer(),
            _RoundIcon(
              icon: Icons.chevron_left,
              tooltip: 'Trang trước',
              onTap: onPrev,
            ),
            const SizedBox(width: 12),
            _RoundIcon(
              icon: Icons.chevron_right,
              tooltip: 'Trang sau',
              onTap: onNext,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _RoundIcon({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, size: 24, color: Theme.of(context).colorScheme.onPrimaryContainer),
          ),
        ),
      ),
    );
  }
}
