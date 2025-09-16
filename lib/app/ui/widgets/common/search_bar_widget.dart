import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final String placeholder;
  final VoidCallback onTap;
  final bool enabled;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final Widget? leading;
  final Widget? trailing;
  final Color? backgroundColor;
  final double elevation;
  final EdgeInsetsGeometry margin;
  final double height;
  final BorderRadiusGeometry? borderRadius;
  final Color? shadowColor;

  const SearchBarWidget({
    super.key,
    this.placeholder = 'Start your search',
    required this.onTap,
    this.enabled = false,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.leading,
    this.trailing,
    this.backgroundColor,
    this.elevation = 2,
    this.margin = const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    this.height = 50,
    this.borderRadius,
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: margin,
        child: Material(
          elevation: elevation,
          borderRadius: borderRadius ?? BorderRadius.circular(30),
          shadowColor: shadowColor ?? Colors.black.withValues(alpha: 0.1),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white,
              borderRadius: borderRadius ?? BorderRadius.circular(30),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child:
                      leading ??
                      Icon(
                        Icons.search_rounded,
                        color: Colors.grey[600],
                        size: 24,
                      ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child:
                      enabled
                          ? TextField(
                            controller: controller,
                            onChanged: onChanged,
                            onSubmitted: onSubmitted,
                            autofocus: true,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: placeholder,
                              hintStyle: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          )
                          : Text(
                            placeholder,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                ),
                if (trailing != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: trailing,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
