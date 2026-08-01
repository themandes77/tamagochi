import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/customization/domain/nti_outfit.dart';
import 'package:flutter_application_1/features/customization/domain/theme_option.dart';
import 'package:flutter_application_1/features/customization/presentation/animated_nti_preview.dart';
import 'package:flutter_application_1/features/store/application/store_controller.dart';
import 'package:flutter_application_1/features/store/domain/shop_item.dart';
import 'package:flutter_application_1/features/store/presentation/store_visual_tokens.dart';

ThemeData storeThemeFrom(ThemeOption _) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: StoreVisualTokens.purple,
      brightness: Brightness.light,
      surface: StoreVisualTokens.cream,
    ),
    scaffoldBackgroundColor: StoreVisualTokens.lavender,
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        color: StoreVisualTokens.purpleDark,
        fontWeight: FontWeight.w900,
      ),
      titleMedium: TextStyle(
        color: StoreVisualTokens.purpleDark,
        fontWeight: FontWeight.w800,
      ),
      bodyMedium: TextStyle(color: StoreVisualTokens.purpleDark),
    ),
  );
}

class StorePreviewApp extends StatelessWidget {
  const StorePreviewApp({required this.controller, super.key});

  final StoreController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Tienda NT Tamagochi',
          theme: storeThemeFrom(controller.selectedTheme),
          home: StoreScreen(controller: controller),
        );
      },
    );
  }
}

class StoreScreen extends StatefulWidget {
  const StoreScreen({required this.controller, this.onClose, super.key});

  final StoreController controller;
  final VoidCallback? onClose;

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  var _selectedPage = 0;
  var _selectedKind = ShopItemKind.outfit;
  String? _previewItemId;

  StoreController get controller => widget.controller;
  bool get _isStorePage => _selectedPage == 0;

  @override
  Widget build(BuildContext context) {
    final visibleItems = controller
        .itemsFor(_selectedKind)
        .where((item) => _isStorePage || controller.isOwned(item))
        .toList(growable: false);
    final previewItem = _findPreviewItem();
    final previewOutfit = _outfitFor(previewItem) ?? controller.selectedOutfit;
    final previewTheme = _themeFor(previewItem) ?? controller.selectedTheme;

    return Scaffold(
      appBar: _StoreHeader(
        isStorePage: _isStorePage,
        coins: controller.coins,
        onBack: _handleBack,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth >= 720 ? 28.0 : 16.0;
          final columnCount = constraints.maxWidth >= 760 ? 4 : 2;
          final cardHeight = _selectedKind == ShopItemKind.outfit
              ? 230.0
              : 238.0;

          return CustomScrollView(
            key: ValueKey('store_page_$_selectedPage'),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  14,
                  horizontalPadding,
                  12,
                ),
                sliver: SliverToBoxAdapter(
                  child: _CustomizationPreview(
                    outfit: previewOutfit,
                    theme: previewTheme,
                    message: previewItem == null
                        ? _isStorePage
                              ? '¡Elige un estilo!'
                              : '¡Vamos a personalizar!'
                        : '¡${previewItem.name} me queda genial!',
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  14,
                ),
                sliver: SliverToBoxAdapter(
                  child: _CategoryTabs(
                    selectedKind: _selectedKind,
                    onSelected: (kind) {
                      setState(() {
                        _selectedKind = kind;
                        _previewItemId = null;
                      });
                    },
                  ),
                ),
              ),
              if (visibleItems.isEmpty)
                const SliverToBoxAdapter(child: _EmptyInventory())
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columnCount,
                      mainAxisExtent: cardHeight,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = visibleItems[index];
                      return _StoreItemCard(
                        item: item,
                        controller: controller,
                        isStorePage: _isStorePage,
                        selected: item.id == _previewItemId,
                        onSelected: () {
                          setState(() => _previewItemId = item.id);
                        },
                        onAction: () => _handleItemAction(item),
                      );
                    }, childCount: visibleItems.length),
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  14,
                  horizontalPadding,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: _CatalogHint(
                    selectedKind: _selectedKind,
                    isStorePage: _isStorePage,
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  12,
                  horizontalPadding,
                  28,
                ),
                sliver: SliverToBoxAdapter(
                  child: _PageSwitchButton(
                    isStorePage: _isStorePage,
                    onPressed: _switchPage,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleBack() {
    if (!_isStorePage) {
      _switchPage();
      return;
    }
    widget.onClose?.call();
  }

  void _switchPage() {
    setState(() {
      _selectedPage = _isStorePage ? 1 : 0;
      _previewItemId = null;
    });
  }

  ShopItem? _findPreviewItem() {
    final id = _previewItemId;
    if (id == null) {
      return null;
    }
    for (final item in controller.catalog) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  NtiOutfit? _outfitFor(ShopItem? item) {
    if (item == null || item.kind != ShopItemKind.outfit) {
      return null;
    }
    for (final outfit in controller.outfits) {
      if (outfit.id == item.customizationId) {
        return outfit;
      }
    }
    return null;
  }

  ThemeOption? _themeFor(ShopItem? item) {
    if (item == null || item.kind != ShopItemKind.theme) {
      return null;
    }
    for (final theme in controller.themes) {
      if (theme.id == item.customizationId) {
        return theme;
      }
    }
    return null;
  }

  Future<void> _handleItemAction(ShopItem item) async {
    setState(() => _previewItemId = item.id);

    if (controller.isOwned(item)) {
      final equipped = await controller.equip(item.id);
      if (!mounted) {
        return;
      }
      _showMessage(equipped ? 'Artículo equipado.' : 'No se pudo equipar.');
      return;
    }

    final result = await controller.purchase(item.id);
    if (!mounted) {
      return;
    }
    _showMessage(switch (result) {
      PurchaseResult.success => 'Compra realizada. Ya puedes equiparlo.',
      PurchaseResult.alreadyOwned => 'Ya tienes este artículo.',
      PurchaseResult.insufficientFunds => 'No tienes suficientes monedas.',
      PurchaseResult.itemNotFound => 'El artículo ya no está disponible.',
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: StoreVisualTokens.purpleDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          content: Text(message),
        ),
      );
  }
}

class _StoreHeader extends StatelessWidget implements PreferredSizeWidget {
  const _StoreHeader({
    required this.isStorePage,
    required this.coins,
    required this.onBack,
  });

  final bool isStorePage;
  final int coins;
  final VoidCallback onBack;

  @override
  Size get preferredSize => const Size.fromHeight(78);

  @override
  Widget build(BuildContext context) {
    final title = isStorePage ? 'TIENDA' : 'PERSONALIZACIÓN';

    return AppBar(
      toolbarHeight: preferredSize.height,
      centerTitle: true,
      automaticallyImplyLeading: false,
      backgroundColor: isStorePage
          ? StoreVisualTokens.purple
          : StoreVisualTokens.cream,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: Border(
        bottom: BorderSide(
          color: isStorePage
              ? StoreVisualTokens.gold
              : StoreVisualTokens.purpleLight,
          width: 3,
        ),
      ),
      leadingWidth: 72,
      leading: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: _RoundHeaderButton(
          key: const ValueKey('store_close_button'),
          tooltip: isStorePage ? 'Cerrar tienda' : 'Volver a la tienda',
          isStorePage: isStorePage,
          onPressed: onBack,
        ),
      ),
      title: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          title,
          maxLines: 1,
          style: TextStyle(
            color: isStorePage
                ? StoreVisualTokens.cream
                : StoreVisualTokens.purple,
            fontSize: isStorePage ? 32 : 27,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            shadows: isStorePage
                ? const [
                    Shadow(
                      color: StoreVisualTokens.goldDark,
                      blurRadius: 2,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        ),
      ),
      actions: [
        if (isStorePage)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _CoinBalance(coins: coins),
          )
        else
          const SizedBox(width: 72),
      ],
    );
  }
}

class _RoundHeaderButton extends StatelessWidget {
  const _RoundHeaderButton({
    required this.tooltip,
    required this.isStorePage,
    required this.onPressed,
    super.key,
  });

  final String tooltip;
  final bool isStorePage;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isStorePage
            ? StoreVisualTokens.cream
            : StoreVisualTokens.lavender,
        shape: CircleBorder(
          side: BorderSide(
            color: isStorePage
                ? StoreVisualTokens.gold
                : StoreVisualTokens.purple,
            width: 2.5,
          ),
        ),
        elevation: 3,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Icon(
            Icons.arrow_back_rounded,
            color: StoreVisualTokens.purple,
          ),
        ),
      ),
    );
  }
}

class _CustomizationPreview extends StatelessWidget {
  const _CustomizationPreview({
    required this.outfit,
    required this.theme,
    required this.message,
  });

  final NtiOutfit outfit;
  final ThemeOption theme;
  final String message;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final previewHeight = (constraints.maxWidth * 0.57).clamp(210.0, 330.0);
        final ntiSize = math.min(previewHeight * 0.84, 236.0);

        return Container(
          height: previewHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(StoreVisualTokens.panelRadius),
            border: Border.all(color: StoreVisualTokens.purple, width: 3),
            boxShadow: const [StoreVisualTokens.softShadow],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedSwitcher(
                duration: StoreVisualTokens.backgroundTransition,
                child: _ThemeBackdrop(key: ValueKey(theme.id), theme: theme),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0x5C261437)],
                    stops: [0.58, 1],
                  ),
                ),
              ),
              Align(
                alignment: const Alignment(0, 0.22),
                child: AnimatedNtiPreview(
                  outfit: outfit,
                  message: message,
                  size: ntiSize,
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: AnimatedSwitcher(
                  duration: StoreVisualTokens.normal,
                  child: _SpeechPill(key: ValueKey(message), message: message),
                ),
              ),
              Positioned(
                left: 12,
                bottom: 10,
                child: _EquippedLabel(outfit: outfit, theme: theme),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SpeechPill extends StatelessWidget {
  const _SpeechPill({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xF5FFF8EA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: StoreVisualTokens.purple, width: 1.5),
        boxShadow: const [StoreVisualTokens.softShadow],
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: StoreVisualTokens.purpleDark,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EquippedLabel extends StatelessWidget {
  const _EquippedLabel({required this.outfit, required this.theme});

  final NtiOutfit outfit;
  final ThemeOption theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xDD3A2252),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x66FFFFFF)),
      ),
      child: Text(
        '${outfit.displayName} · ${theme.displayName}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ThemeBackdrop extends StatelessWidget {
  const _ThemeBackdrop({required this.theme, super.key});

  final ThemeOption theme;

  @override
  Widget build(BuildContext context) {
    final assetPath = theme.flutterBackgroundAssetPath;
    if (assetPath != null) {
      return Image.asset(assetPath, fit: BoxFit.cover);
    }

    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF4DF), Color(0xFFE5CEF5)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.auto_awesome_rounded,
          color: Color(0x667446B8),
          size: 52,
        ),
      ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({required this.selectedKind, required this.onSelected});

  final ShopItemKind selectedKind;
  final ValueChanged<ShopItemKind> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: StoreVisualTokens.purpleLight,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [StoreVisualTokens.softShadow],
      ),
      child: Row(
        children: [
          Expanded(
            child: _CategoryTab(
              label: 'TRAJES',
              icon: Icons.checkroom_rounded,
              selected: selectedKind == ShopItemKind.outfit,
              onTap: () => onSelected(ShopItemKind.outfit),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: _CategoryTab(
              label: 'FONDOS',
              icon: Icons.image_rounded,
              selected: selectedKind == ShopItemKind.theme,
              onTap: () => onSelected(ShopItemKind.theme),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: StoreVisualTokens.normal,
      decoration: BoxDecoration(
        color: selected ? StoreVisualTokens.cream : Colors.transparent,
        borderRadius: BorderRadius.circular(19),
        border: selected
            ? Border.all(color: StoreVisualTokens.gold, width: 2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('category_${label.toLowerCase()}'),
          borderRadius: BorderRadius.circular(19),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: StoreVisualTokens.purple, size: 23),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    style: const TextStyle(
                      color: StoreVisualTokens.purpleDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreItemCard extends StatelessWidget {
  const _StoreItemCard({
    required this.item,
    required this.controller,
    required this.isStorePage,
    required this.selected,
    required this.onSelected,
    required this.onAction,
  });

  final ShopItem item;
  final StoreController controller;
  final bool isStorePage;
  final bool selected;
  final VoidCallback onSelected;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final owned = controller.isOwned(item);
    final equipped = controller.isEquipped(item);

    return AnimatedScale(
      scale: selected ? 1 : 0.985,
      duration: StoreVisualTokens.quick,
      child: AnimatedContainer(
        duration: StoreVisualTokens.normal,
        decoration: BoxDecoration(
          color: StoreVisualTokens.cream,
          borderRadius: BorderRadius.circular(StoreVisualTokens.cardRadius),
          border: Border.all(
            color: selected
                ? StoreVisualTokens.purple
                : StoreVisualTokens.creamStrong,
            width: selected ? 3 : 1.5,
          ),
          boxShadow: const [StoreVisualTokens.softShadow],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('store_item_${item.id}'),
            borderRadius: BorderRadius.circular(StoreVisualTokens.cardRadius),
            onTap: onSelected,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: _ItemPreview(item: item, controller: controller),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: StoreVisualTokens.purpleDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 7),
                  _ItemActionButton(
                    item: item,
                    owned: owned,
                    equipped: equipped,
                    isStorePage: isStorePage,
                    onPressed: equipped ? null : onAction,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemActionButton extends StatelessWidget {
  const _ItemActionButton({
    required this.item,
    required this.owned,
    required this.equipped,
    required this.isStorePage,
    required this.onPressed,
  });

  final ShopItem item;
  final bool owned;
  final bool equipped;
  final bool isStorePage;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isPurchase = isStorePage && !owned;
    final label = equipped
        ? 'Equipado'
        : owned
        ? 'Equipar'
        : item.price == 0
        ? 'Gratis'
        : '${item.price}';
    final foreground = isPurchase
        ? StoreVisualTokens.purpleDark
        : StoreVisualTokens.cream;
    final colors = isPurchase
        ? const [Color(0xFFFFE19B), Color(0xFFF4BB4C)]
        : equipped
        ? const [Color(0xFF8B5BC9), Color(0xFF6840A2)]
        : const [Color(0xFF9A69D4), Color(0xFF7446B8)];

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: '$label ${item.name}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('store_action_${item.id}'),
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed,
          child: AnimatedContainer(
            duration: StoreVisualTokens.quick,
            width: double.infinity,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isPurchase
                    ? StoreVisualTokens.goldDark
                    : StoreVisualTokens.purpleLight,
                width: 1.5,
              ),
              boxShadow: isPurchase
                  ? const [StoreVisualTokens.goldShadow]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  equipped
                      ? Icons.check_circle_rounded
                      : owned
                      ? Icons.checkroom_rounded
                      : Icons.monetization_on_rounded,
                  color: equipped ? const Color(0xFFB8F27E) : foreground,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemPreview extends StatelessWidget {
  const _ItemPreview({required this.item, required this.controller});

  final ShopItem item;
  final StoreController controller;

  @override
  Widget build(BuildContext context) {
    if (item.kind == ShopItemKind.theme) {
      final theme = _findTheme();
      final assetPath = theme?.flutterBackgroundAssetPath;
      return AspectRatio(
        aspectRatio: 1.22,
        child: Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Color(theme?.backgroundColorValue ?? 0xFFEEEEEE),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: StoreVisualTokens.creamStrong),
          ),
          child: assetPath == null
              ? const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFE8E2E8), Color(0xFFCFC7D0)],
                    ),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: StoreVisualTokens.purple,
                    size: 36,
                  ),
                )
              : Image.asset(assetPath, fit: BoxFit.cover),
        ),
      );
    }

    final outfit = _findOutfit();
    return outfit == null
        ? const SizedBox.square(dimension: 112)
        : NtiStaticPreview(outfit: outfit, size: 118);
  }

  NtiOutfit? _findOutfit() {
    for (final outfit in controller.outfits) {
      if (outfit.id == item.customizationId) {
        return outfit;
      }
    }
    return null;
  }

  ThemeOption? _findTheme() {
    for (final theme in controller.themes) {
      if (theme.id == item.customizationId) {
        return theme;
      }
    }
    return null;
  }
}

class _CoinBalance extends StatelessWidget {
  const _CoinBalance({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF5F3691),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: StoreVisualTokens.gold, width: 2),
          boxShadow: const [StoreVisualTokens.goldShadow],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: StoreVisualTokens.normal,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child: Text(
                '$coins',
                key: ValueKey(coins),
                style: const TextStyle(
                  color: StoreVisualTokens.cream,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.monetization_on_rounded,
              color: Color(0xFFFFD967),
              size: 21,
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogHint extends StatelessWidget {
  const _CatalogHint({required this.selectedKind, required this.isStorePage});

  final ShopItemKind selectedKind;
  final bool isStorePage;

  @override
  Widget build(BuildContext context) {
    final message = isStorePage
        ? selectedKind == ShopItemKind.outfit
              ? 'Los trajes cambian la apariencia de tu NTI.'
              : 'Los fondos transforman la habitación de NTI.'
        : 'Toca un artículo para verlo y equiparlo.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xBFFFF8EA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: StoreVisualTokens.creamStrong),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.star_rounded,
            color: StoreVisualTokens.gold,
            size: 22,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: StoreVisualTokens.purpleDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageSwitchButton extends StatelessWidget {
  const _PageSwitchButton({required this.isStorePage, required this.onPressed});

  final bool isStorePage;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey(isStorePage ? 'open_inventory' : 'open_store'),
        onTap: onPressed,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          height: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF9562CC), StoreVisualTokens.purple],
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: StoreVisualTokens.gold, width: 2),
            boxShadow: const [StoreVisualTokens.softShadow],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isStorePage
                    ? Icons.inventory_2_rounded
                    : Icons.storefront_rounded,
                color: const Color(0xFFFFD967),
                size: 27,
              ),
              const SizedBox(width: 10),
              Text(
                isStorePage ? 'MIS ARTÍCULOS' : 'VOLVER A LA TIENDA',
                style: const TextStyle(
                  color: StoreVisualTokens.cream,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyInventory extends StatelessWidget {
  const _EmptyInventory();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: Column(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            color: StoreVisualTokens.purple,
            size: 52,
          ),
          const SizedBox(height: 10),
          Text(
            'Todavía no tienes artículos de esta categoría.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
