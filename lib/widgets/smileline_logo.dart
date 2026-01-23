import 'package:flutter/material.dart';
import '../config/constants.dart';

class SmileLineLogo extends StatelessWidget {
  final double size;
  final Color? tintColor;
  final EdgeInsets? padding;
  final bool showText;
  final Alignment alignment;

  const SmileLineLogo({
    Key? key,
    this.size = 80.0,
    this.tintColor,
    this.padding,
    this.showText = false,
    this.alignment = Alignment.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            AppConstants.logoPath,
            width: size,
            height: size,
            fit: BoxFit.contain,
            color: tintColor,
            colorBlendMode: tintColor != null ? BlendMode.srcIn : BlendMode.dst,
          ),

          if (showText)
            Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: tintColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SmileLineAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final bool showLogo;
  final Color? backgroundColor;

  const SmileLineAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.onBackPressed,
    this.showLogo = true,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      leading: onBackPressed != null
          ? IconButton(
        icon: Icon(Icons.arrow_back_ios, size: 18),
        onPressed: onBackPressed,
      )
          : null,
      title: Row(
        children: [
          if (showLogo)
            Image.asset(
              AppConstants.logoPath,
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
          if (showLogo) SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: actions,
      centerTitle: false,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(56);
}