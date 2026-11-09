import 'package:flutter/material.dart';

import '../../config/app_colors.dart';

class SwipeUpButton extends StatefulWidget {
  const SwipeUpButton({
    super.key,
    required this.label,
    required this.onCompleted,
  });

  final String label;
  final VoidCallback onCompleted;

  @override
  State<SwipeUpButton> createState() => _SwipeUpButtonState();
}

class _SwipeUpButtonState extends State<SwipeUpButton> {
  static const double _height = 56;
  static const double _handleSize = 44;
  static const double _threshold = 60;

  double _dy = 0;
  bool _dragging = false;

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragging = true;
      _dy = (_dy + details.delta.dy).clamp(-_threshold * 1.5, 0.0).toDouble();
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final completed = _dy <= -_threshold;
    setState(() {
      _dragging = false;
      _dy = 0;
    });
    if (completed) widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onCompleted,
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      child: Container(
        height: _height,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_height / 2),
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: _dragging ? 0 : 200),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(0, _dy, 0),
              width: _handleSize,
              height: _handleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.teal, width: 1.5),
              ),
              child: const Icon(
                Icons.north_east,
                size: 18,
                color: AppColors.teal,
              ),
            ),
            Expanded(
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.north_east,
                      size: 12,
                      color: AppColors.teal,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: _handleSize),
          ],
        ),
      ),
    );
  }
}