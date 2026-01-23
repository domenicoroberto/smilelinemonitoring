import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final int maxLines;
  final int? maxLength;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onShowPassword;
  final bool isRequired;

  const CustomTextField({
    Key? key,
    required this.label,
    this.hint,
    required this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.maxLength,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onShowPassword,
    this.isRequired = false,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: widget.label,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              if (widget.isRequired)
                TextSpan(
                  text: ' *',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.red,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          obscureText: widget.obscureText ? _obscureText : false,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.obscureText
                ? IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
                widget.onShowPassword?.call();
              },
            )
                : widget.suffixIcon,
          ),
        ),
      ],
    );
  }
}