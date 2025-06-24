import 'package:flutter/material.dart';

import '../../models/themes/quill_icon_theme.dart';
import '../toolbar.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    required this.onPressed,
    required this.icon,
    this.svgIcon,
    this.iconColor,
    this.iconSize = kDefaultIconSize,
    this.iconTheme,
    this.afterButtonPressed,
    this.tooltip,
    this.iconColorDisabled,
    Key? key,
  }) : super(key: key);

  final VoidCallback? onPressed;
  final IconData? icon;
  final String? svgIcon;
  final Color? iconColor;
  final double iconSize;
  final QuillIconTheme? iconTheme;
  final VoidCallback? afterButtonPressed;
  final String? tooltip;
  final Color? iconColorDisabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final iconColor = onPressed != null
        ? this.iconColor ??
            iconTheme?.iconUnselectedColor ??
            theme.iconTheme.color
        : iconColorDisabled ??
            iconTheme?.disabledIconColor ??
            theme.disabledColor;
    return QuillIconButton(
      highlightElevation: 0,
      hoverElevation: 0,
      size: iconSize * kIconButtonFactor,
      icon: QuillSvgPicture(
        iconColor: iconColor,
        iconSize: iconSize,
        icon: icon,
        svgIcon: svgIcon,
      ),
      tooltip: tooltip,
      borderRadius: iconTheme?.borderRadius ?? 2,
      onPressed: onPressed,
      afterPressed: afterButtonPressed,
      fillColor: iconTheme?.iconUnselectedFillColor ?? theme.canvasColor,
    );
  }
}
