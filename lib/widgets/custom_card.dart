import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final double borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double elevation;
  final VoidCallback? onTap;
  final Border? border;

  const CustomCard({
    Key? key,
    required this.child,
    this.backgroundColor,
    this.borderRadius = 16,
    this.padding,
    this.margin,
    this.elevation = 2,
    this.onTap,
    this.border,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor,
      margin: margin,
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: border?.top ?? BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding ?? EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}