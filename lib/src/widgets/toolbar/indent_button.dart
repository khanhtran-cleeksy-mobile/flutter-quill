import 'package:flutter/material.dart';

import '../../../flutter_quill.dart';

class IndentButton extends StatefulWidget {
  const IndentButton({
    required this.icon,
    required this.controller,
    required this.isIncrease,
    this.iconSize = kDefaultIconSize,
    this.iconTheme,
    this.afterButtonPressed,
    this.tooltip,
    this.colorDisabled,
    Key? key,
  }) : super(key: key);

  final IconData icon;
  final double iconSize;
  final QuillController controller;
  final bool isIncrease;
  final VoidCallback? afterButtonPressed;

  final QuillIconTheme? iconTheme;
  final String? tooltip;
  final Color? colorDisabled;

  @override
  _IndentButtonState createState() => _IndentButtonState();
}

class _IndentButtonState extends State<IndentButton> {
  bool? _isDisabled;

  Style get _selectionStyle => widget.controller.getSelectionStyle();

  @override
  void initState() {
    super.initState();
    _isDisabled = _getIsDisabled(_selectionStyle.attributes);
    widget.controller.addListener(_didChangeEditingValue);
  }

  @override
  void didUpdateWidget(covariant IndentButton oldWidget) {
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_didChangeEditingValue);
      widget.controller.addListener(_didChangeEditingValue);
      _isDisabled = _getIsDisabled(_selectionStyle.attributes);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_didChangeEditingValue);
    super.dispose();
  }

  void _didChangeEditingValue() {
    setState(() => _isDisabled = _getIsDisabled(_selectionStyle.attributes));
  }

  bool _getIsDisabled(Map<String, Attribute> attrs) {
    final attribute = attrs[Attribute.indent.key];
    if (attribute == null) {
      if (attrs[Attribute.list.key] != null) {
        return false;
      }
      return !widget.isIncrease;
    }
    return widget.isIncrease ? attribute.value >= 5 : attribute.value <= 0;
  }

  ThemeData get theme => Theme.of(context);

  Color? get iconColor => _isDisabled == true
      ? widget.colorDisabled ?? theme.disabledColor
      : widget.iconTheme?.iconUnselectedColor ?? theme.iconTheme.color;
  Color? get iconFillColor =>
      widget.iconTheme?.iconUnselectedFillColor ?? theme.canvasColor;

  @override
  Widget build(BuildContext context) {
    return QuillIconButton(
      tooltip: widget.tooltip,
      highlightElevation: 0,
      hoverElevation: 0,
      size: widget.iconSize * 1.77,
      icon: Icon(widget.icon, size: widget.iconSize, color: iconColor),
      fillColor: iconFillColor,
      borderRadius: widget.iconTheme?.borderRadius ?? 2,
      onPressed: () {
        widget.controller.indentSelection(widget.isIncrease);
      },
      afterPressed: widget.afterButtonPressed,
      isDisabled: _isDisabled ?? false,
    );
  }
}
