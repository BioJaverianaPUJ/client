import 'package:flutter/widgets.dart';

class BioPressable extends StatefulWidget {
  const BioPressable({
    super.key,
    required this.child,
    this.onTap,
    this.pressedOpacity = 0.76,
    this.pressedScale = 0.985,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedOpacity;
  final double pressedScale;

  @override
  State<BioPressable> createState() => _BioPressableState();
}

class _BioPressableState extends State<BioPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 90);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
      onTapUp: widget.onTap == null ? null : (_) => _setPressed(false),
      onTapCancel: widget.onTap == null ? null : () => _setPressed(false),
      child: AnimatedOpacity(
        duration: duration,
        opacity: _pressed ? widget.pressedOpacity : 1,
        child: AnimatedScale(
          duration: duration,
          scale: _pressed ? widget.pressedScale : 1,
          child: widget.child,
        ),
      ),
    );
  }
}
