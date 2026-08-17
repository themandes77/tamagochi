import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/store/domain/shop_item.dart';
import 'package:flutter_application_1/features/store/presentation/store_visual_tokens.dart';

class StoreCategoryTabs extends StatelessWidget {
  static const panelOverlap = 8.0;

  static double visualHeightForWidth(double width) => width < 360 ? 54 : 60;

  static double layoutHeightForWidth(double width) =>
      visualHeightForWidth(width) - panelOverlap;

  const StoreCategoryTabs({
    required this.selectedKind,
    required this.onSelected,
    super.key,
  });

  final ShopItemKind selectedKind;
  final ValueChanged<ShopItemKind> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final tabHeight = visualHeightForWidth(constraints.maxWidth);
        final widthFactor = compact
            ? 0.86
            : constraints.maxWidth < 600
            ? 0.72
            : 0.64;

        return Center(
          child: FractionallySizedBox(
            widthFactor: widthFactor,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: SizedBox(
                height: layoutHeightForWidth(constraints.maxWidth),
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  minHeight: tabHeight,
                  maxHeight: tabHeight,
                  child: Row(
                    children: [
                      Expanded(
                        child: _StoreCategoryTab(
                          label: 'TRAJES',
                          icon: Icons.checkroom_rounded,
                          selected: selectedKind == ShopItemKind.outfit,
                          compact: compact,
                          onTap: () => onSelected(ShopItemKind.outfit),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: _StoreCategoryTab(
                          label: 'FONDOS',
                          icon: Icons.image_rounded,
                          selected: selectedKind == ShopItemKind.theme,
                          compact: compact,
                          onTap: () => onSelected(ShopItemKind.theme),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StoreCategoryTab extends StatelessWidget {
  const _StoreCategoryTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  static const _selectedAssetPath =
      'assets/images/ui/category_tab_selected_v1.png';
  static const _inactiveAssetPath =
      'assets/images/ui/category_tab_inactive_v1.png';

  final String label;
  final IconData icon;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final keyName = label.toLowerCase();

    return AnimatedPadding(
      duration: StoreVisualTokens.normal,
      padding: EdgeInsets.only(top: selected ? 0 : 5),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [StoreVisualTokens.tabShadow],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              selected ? _selectedAssetPath : _inactiveAssetPath,
              key: ValueKey('category_tab_${keyName}_background'),
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
              excludeFromSemantics: true,
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                key: ValueKey('category_$keyName'),
                borderRadius: BorderRadius.circular(20),
                onTap: onTap,
                splashColor: const Color(0x337446B8),
                highlightColor: const Color(0x197446B8),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 6 : 10,
                    selected ? 7 : 5,
                    compact ? 6 : 10,
                    8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        color: selected
                            ? StoreVisualTokens.purple
                            : const Color(0xFF77559A),
                        size: compact ? 21 : 29,
                      ),
                      SizedBox(width: compact ? 5 : 8),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          style: TextStyle(
                            color: selected
                                ? StoreVisualTokens.purpleDark
                                : const Color(0xFF77559A),
                            fontWeight: FontWeight.w700,
                            fontSize: compact ? 15 : 20,
                            letterSpacing: 0.2,
                            shadows: const [StoreVisualTokens.textShadow],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
