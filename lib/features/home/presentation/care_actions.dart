import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/home/application/care_tool.dart';

class CareActions extends StatelessWidget {
  const CareActions({
    required this.selectedTool,
    required this.enabled,
    required this.onToolPressed,
    super.key,
  });

  final CareTool selectedTool;
  final bool enabled;
  final ValueChanged<CareTool> onToolPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _ToolButton(
              label: 'Comida',
              assetPath: 'assets/images/fridge.png',
              selected: selectedTool == CareTool.food,
              enabled: enabled,
              onPressed: () => onToolPressed(CareTool.food),
            ),
            const SizedBox(width: 18),
            _ToolButton(
              label: 'Jabón',
              assetPath: 'assets/images/soap.png',
              selected: selectedTool == CareTool.soap,
              enabled: enabled,
              onPressed: () => onToolPressed(CareTool.soap),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.label,
    required this.assetPath,
    required this.selected,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final String assetPath;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: label,
      child: Material(
        color: selected
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: 88,
            height: 76,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset(assetPath, width: 38, height: 38),
                const SizedBox(height: 4),
                Text(label),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
