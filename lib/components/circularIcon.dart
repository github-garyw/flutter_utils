import 'package:flutter/material.dart';

class CircularIcon extends StatelessWidget {
  final IconData _icon;
  final Color _bgColor;
  final Color _frontColor;
  final double _shapeSize;
  final double _iconSize;
  final VoidCallback _onTap;

  const CircularIcon({
    super.key,
    IconData icon = Icons.add,
    Color bgColor = Colors.blue,
    Color frontColor = Colors.white,
    double iconSize = 30.0,
    double shapeSize = 30.0,
    required VoidCallback onTap,
  })  : _icon = icon,
        _bgColor = bgColor,
        _frontColor = frontColor,
        _iconSize = iconSize,
        _shapeSize = shapeSize,
        _onTap = onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _onTap,
      child: Container(
        width: _shapeSize, // Adjust the size as needed
        height: _shapeSize, // Adjust the size as needed
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _bgColor,
        ),
        child: Center(
          child: Icon(
            _icon,
            color: _frontColor,
            size: _iconSize,
          ),
        ),
      ),
    );
  }
}
