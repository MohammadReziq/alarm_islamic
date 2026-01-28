import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Microphone animation widget - subtle pulse effect
class MicAnimation extends StatefulWidget {
  final bool isListening;
  final double size;

  const MicAnimation({
    super.key,
    required this.isListening,
    this.size = 80,
  });

  @override
  State<MicAnimation> createState() => _MicAnimationState();
}

class _MicAnimationState extends State<MicAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.isListening) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(MicAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isListening && !oldWidget.isListening) {
      _controller.repeat();
    } else if (!widget.isListening && oldWidget.isListening) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 2,
      height: widget.size * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripple effect
          if (widget.isListening)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  width: widget.size * _scaleAnimation.value,
                  height: widget.size * _scaleAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.gold.withOpacity(_opacityAnimation.value),
                  ),
                );
              },
            ),

          // Microphone icon
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: widget.isListening
                  ? AppTheme.goldGradient
                  : const LinearGradient(
                      colors: [Color(0xFF131B3A), Color(0xFF1A2347)],
                    ),
              border: Border.all(
                color: AppTheme.gold,
                width: 2,
              ),
            ),
            child: Icon(
              widget.isListening ? Icons.mic : Icons.mic_none,
              size: widget.size * 0.5,
              color: widget.isListening
                  ? AppTheme.midnight
                  : AppTheme.gold,
            ),
          ),
        ],
      ),
    );
  }
}
