import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/customization/domain/nti_outfit.dart';
import 'package:flutter_application_1/features/customization/domain/theme_option.dart';
import 'package:flutter_application_1/features/customization/presentation/animated_nti_preview.dart';
import 'package:flutter_application_1/features/store/application/store_controller.dart';
import 'package:flutter_application_1/features/store/domain/shop_item.dart';
import 'package:flutter_application_1/features/store/presentation/store_back_button.dart';
import 'package:flutter_application_1/features/store/presentation/store_catalog_hint.dart';
import 'package:flutter_application_1/features/store/presentation/store_catalog_panel.dart';
import 'package:flutter_application_1/features/store/presentation/store_category_tabs.dart';
import 'package:flutter_application_1/features/store/presentation/store_coin_balance.dart';
import 'package:flutter_application_1/features/store/presentation/store_item_action_button_frame.dart';
import 'package:flutter_application_1/features/store/presentation/store_item_card_frame.dart';
import 'package:flutter_application_1/features/store/presentation/store_showcase_stage.dart';
import 'package:flutter_application_1/features/store/presentation/store_visual_tokens.dart';

ThemeData storeThemeFrom(ThemeOption _) {
  return ThemeData(
    useMaterial3: true,
    fontFamily: StoreVisualTokens.fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: StoreVisualTokens.purple,
      brightness: Brightness.light,
      surface: StoreVisualTokens.cream,
    ),
    scaffoldBackgroundColor: StoreVisualTokens.storeBackdrop,
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        color: StoreVisualTokens.purpleDark,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: StoreVisualTokens.purpleDark,
        fontWeight: FontWeight.w700,
      ),
      bodyMedium: TextStyle(
        color: StoreVisualTokens.purpleDark,
        fontWeight: FontWeight.w600,
      ),
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
  const StoreScreen({
    required this.controller,
    this.onClose,
    this.initialKind = ShopItemKind.outfit,
    super.key,
  });

  final StoreController controller;
  final VoidCallback? onClose;
  final ShopItemKind initialKind;

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreLayoutSpec {
  const _StoreLayoutSpec({
    required this.catalogInset,
    required this.columnCount,
    required this.cardSpacing,
    required this.panelPadding,
    required this.baseCardHeight,
  });

  static const maxContentWidth = 960.0;

  factory _StoreLayoutSpec.fromWidth(double width) {
    final effectiveWidth = math.min(width, maxContentWidth);
    if (effectiveWidth < 360) {
      return const _StoreLayoutSpec(
        catalogInset: 4,
        columnCount: 2,
        cardSpacing: 6,
        panelPadding: 14,
        baseCardHeight: 190,
      );
    }
    if (effectiveWidth < 760) {
      return const _StoreLayoutSpec(
        catalogInset: 6,
        columnCount: 2,
        cardSpacing: 12,
        panelPadding: 22,
        baseCardHeight: 205,
      );
    }
    return const _StoreLayoutSpec(
      catalogInset: 12,
      columnCount: 4,
      cardSpacing: 12,
      panelPadding: 22,
      baseCardHeight: 205,
    );
  }

  final double catalogInset;
  final int columnCount;
  final double cardSpacing;
  final double panelPadding;
  final double baseCardHeight;

  double cardHeightFor(ShopItemKind kind) {
    return baseCardHeight + (kind == ShopItemKind.theme ? 8 : 0);
  }

  double previewSizeFor(double cardWidth) {
    return (cardWidth * 0.8).clamp(106.0, 150.0);
  }

  double actionButtonWidthFor(double cardWidth, {required bool compact}) {
    final horizontalCardPadding = compact ? 14.0 : 20.0;
    final availableWidth = math.max(0.0, cardWidth - horizontalCardPadding);
    return (availableWidth * (compact ? 0.82 : 0.78))
        .clamp(compact ? 104.0 : 126.0, compact ? 132.0 : 160.0)
        .toDouble();
  }
}

class _StoreScreenState extends State<StoreScreen> {
  static const _headerRoomUnderlap = 18.0;

  late ShopItemKind _selectedKind;
  String? _previewItemId;

  StoreController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _selectedKind = widget.initialKind == ShopItemKind.food
        ? ShopItemKind.outfit
        : widget.initialKind;
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = controller.itemsFor(_selectedKind);
    final previewItem = _findPreviewItem();
    final previewOutfit = _outfitFor(previewItem) ?? controller.selectedOutfit;
    final previewTheme = _themeFor(previewItem) ?? controller.selectedTheme;
    final headerLayout = _StoreHeaderLayoutSpec.fromWidth(
      MediaQuery.sizeOf(context).width,
    );
    final usesStoreRoom = _selectedKind == ShopItemKind.outfit;
    final headerObstructionHeight =
        headerLayout.height + MediaQuery.paddingOf(context).top;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _StoreHeader(
        coins: controller.coins,
        onBack: _handleBack,
        layout: headerLayout,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final layout = _StoreLayoutSpec.fromWidth(constraints.maxWidth);
          final catalogGridWidth = math.max(
            0.0,
            math.min(constraints.maxWidth, _StoreLayoutSpec.maxContentWidth) -
                layout.panelPadding * 2,
          );
          final itemWidth =
              (catalogGridWidth -
                  layout.cardSpacing * (layout.columnCount - 1)) /
              layout.columnCount;
          final compactCard = itemWidth < 150;

          return CustomScrollView(
            key: const ValueKey('store_page'),
            slivers: [
              SliverToBoxAdapter(
                child: LayoutBuilder(
                  builder: (context, showcaseConstraints) {
                    final tabsWidth = math.max(
                      0.0,
                      math.min(
                            showcaseConstraints.maxWidth,
                            _StoreLayoutSpec.maxContentWidth,
                          ) -
                          layout.catalogInset * 2,
                    );
                    final tabsLayoutHeight =
                        StoreCategoryTabs.layoutHeightForWidth(tabsWidth);

                    return Padding(
                      key: const ValueKey('store_showcase_header_layer'),
                      padding: EdgeInsets.only(
                        top: math.max(
                          0,
                          headerObstructionHeight - _headerRoomUnderlap,
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _CustomizationPreview(
                            outfit: previewOutfit,
                            theme: previewTheme,
                            useStoreRoom: usesStoreRoom,
                            bottomReservedHeight: tabsLayoutHeight,
                            message: previewItem == null
                                ? '¡Elige un estilo!'
                                : '¡${previewItem.name} me queda genial!',
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: _StoreLayoutSpec.maxContentWidth,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: layout.catalogInset,
                                  ),
                                  child: StoreCategoryTabs(
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
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: StoreCatalogPanel(
                  padding: EdgeInsets.fromLTRB(
                    layout.panelPadding,
                    layout.panelPadding,
                    layout.panelPadding,
                    math.max(16, layout.panelPadding - 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (visibleItems.isEmpty)
                        const _EmptyInventory()
                      else
                        Center(
                          child: SizedBox(
                            width: catalogGridWidth,
                            child: Wrap(
                              spacing: layout.cardSpacing,
                              runSpacing: layout.cardSpacing,
                              children: [
                                for (final item in visibleItems)
                                  SizedBox(
                                    width: itemWidth,
                                    height: layout.cardHeightFor(_selectedKind),
                                    child: _StoreItemCard(
                                      item: item,
                                      controller: controller,
                                      compact: compactCard,
                                      previewSize: layout.previewSizeFor(
                                        itemWidth,
                                      ),
                                      actionButtonWidth: layout
                                          .actionButtonWidthFor(
                                            itemWidth,
                                            compact: compactCard,
                                          ),
                                      selected: item.id == _previewItemId,
                                      onSelected: () {
                                        setState(
                                          () => _previewItemId = item.id,
                                        );
                                      },
                                      onAction: () => _handleItemAction(item),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 10),
                          StoreCatalogHint(
                            selectedKind: _selectedKind,
                            isStorePage: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleBack() => widget.onClose?.call();

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

class _StoreHeaderLayoutSpec {
  const _StoreHeaderLayoutSpec({
    required this.contentWidth,
    required this.height,
    required this.backInset,
    required this.backSize,
    required this.titleWidth,
    required this.titleHeight,
    required this.balanceInset,
    required this.balanceWidth,
    required this.balanceHeight,
  });

  factory _StoreHeaderLayoutSpec.fromWidth(double screenWidth) {
    const referenceWidth = 942.0;
    final contentWidth = math.min(
      screenWidth,
      _StoreLayoutSpec.maxContentWidth,
    );

    return _StoreHeaderLayoutSpec(
      contentWidth: contentWidth,
      height: (contentWidth * 193 / referenceWidth).clamp(72.0, 198.0),
      backInset: contentWidth * 45 / referenceWidth,
      backSize: (contentWidth * 116 / referenceWidth).clamp(44.0, 118.0),
      titleWidth: (contentWidth * 333 / referenceWidth).clamp(112.0, 340.0),
      titleHeight: (contentWidth * 104 / referenceWidth).clamp(42.0, 106.0),
      balanceInset: contentWidth * 39 / referenceWidth,
      balanceWidth: (contentWidth * 204 / referenceWidth).clamp(74.0, 208.0),
      balanceHeight: (contentWidth * 78 / referenceWidth).clamp(31.0, 80.0),
    );
  }

  final double contentWidth;
  final double height;
  final double backInset;
  final double backSize;
  final double titleWidth;
  final double titleHeight;
  final double balanceInset;
  final double balanceWidth;
  final double balanceHeight;
}

class _StoreHeader extends StatelessWidget implements PreferredSizeWidget {
  static const _storePanelAssetPath =
      'assets/images/ui/store_header_panel_v1.png';
  static const _storeTitleAssetPath = 'assets/images/ui/store_title_v1.png';

  const _StoreHeader({
    required this.coins,
    required this.onBack,
    required this.layout,
  });

  final int coins;
  final VoidCallback onBack;
  final _StoreHeaderLayoutSpec layout;

  @override
  Size get preferredSize => Size.fromHeight(layout.height);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: layout.height,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 0,
      flexibleSpace: Image.asset(
        _storePanelAssetPath,
        key: const ValueKey('store_header_panel_asset'),
        fit: BoxFit.fill,
        filterQuality: FilterQuality.high,
        excludeFromSemantics: true,
      ),
      title: Center(
        child: SizedBox(
          width: layout.contentWidth,
          height: layout.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                key: const ValueKey('store_header_back_slot'),
                left: layout.backInset,
                top: (layout.height - layout.backSize) / 2,
                width: layout.backSize,
                height: layout.backSize,
                child: StoreBackButton(
                  key: const ValueKey('store_close_button'),
                  tooltip: 'Cerrar tienda',
                  size: layout.backSize,
                  onPressed: onBack,
                ),
              ),
              Positioned(
                key: const ValueKey('store_header_title_slot'),
                left: (layout.contentWidth - layout.titleWidth) / 2,
                top: (layout.height - layout.titleHeight) / 2,
                width: layout.titleWidth,
                height: layout.titleHeight,
                child: Semantics(
                  label: 'TIENDA',
                  image: true,
                  child: Image.asset(
                    _storeTitleAssetPath,
                    key: const ValueKey('store_title_asset'),
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
              Positioned(
                key: const ValueKey('store_header_balance_slot'),
                right: layout.balanceInset,
                top: (layout.height - layout.balanceHeight) / 2,
                width: layout.balanceWidth,
                height: layout.balanceHeight,
                child: StoreCoinBalance(
                  coins: coins,
                  width: layout.balanceWidth,
                  height: layout.balanceHeight,
                ),
              ),
            ],
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
    required this.useStoreRoom,
    required this.bottomReservedHeight,
    required this.message,
  });

  final NtiOutfit outfit;
  final ThemeOption theme;
  final bool useStoreRoom;
  final double bottomReservedHeight;
  final String message;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final previewHeight = (constraints.maxWidth * 0.57).clamp(
          compact ? 190.0 : 210.0,
          360.0,
        );
        final totalHeight = previewHeight + bottomReservedHeight;

        if (useStoreRoom) {
          return SizedBox(
            width: double.infinity,
            height: totalHeight,
            child: StoreShowcaseStage(
              outfit: outfit,
              message: message,
              foregroundHeight: previewHeight,
            ),
          );
        }

        final ntiSize = math.min(previewHeight * 0.84, 236.0);

        return Container(
          key: const ValueKey('store_theme_showcase'),
          width: double.infinity,
          height: totalHeight,
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
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [...previousChildren, ?currentChild],
                  );
                },
                child: SizedBox.expand(
                  key: ValueKey(theme.id),
                  child: _ThemeBackdrop(theme: theme),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                height: previewHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
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
                      alignment: const Alignment(0, 0.68),
                      child: _NtiContactShadow(width: ntiSize * 0.6),
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
                        child: _SpeechPill(
                          key: ValueKey(message),
                          message: message,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 10,
                      child: _EquippedLabel(outfit: outfit, theme: theme),
                    ),
                  ],
                ),
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
          fontWeight: FontWeight.w700,
          fontSize: 12,
          shadows: [StoreVisualTokens.textShadow],
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
          fontWeight: FontWeight.w700,
          fontSize: 12,
          shadows: [StoreVisualTokens.textShadow],
        ),
      ),
    );
  }
}

class _ThemeBackdrop extends StatelessWidget {
  const _ThemeBackdrop({required this.theme});

  final ThemeOption theme;

  @override
  Widget build(BuildContext context) {
    final assetPath = theme.flutterBackgroundAssetPath;
    if (assetPath != null) {
      return Image.asset(
        assetPath,
        key: const ValueKey('store_theme_background_asset'),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        excludeFromSemantics: true,
      );
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

class _NtiContactShadow extends StatelessWidget {
  const _NtiContactShadow({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: width,
        height: math.max(8, width * 0.11),
        decoration: BoxDecoration(
          color: const Color(0x10000000),
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [StoreVisualTokens.contactShadow],
        ),
      ),
    );
  }
}

class _StoreItemCard extends StatelessWidget {
  const _StoreItemCard({
    required this.item,
    required this.controller,
    required this.compact,
    required this.previewSize,
    required this.actionButtonWidth,
    required this.selected,
    required this.onSelected,
    required this.onAction,
  });

  final ShopItem item;
  final StoreController controller;
  final bool compact;
  final double previewSize;
  final double actionButtonWidth;
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
      child: StoreItemCardFrame(
        selected: selected,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('store_item_${item.id}'),
            borderRadius: BorderRadius.circular(StoreVisualTokens.cardRadius),
            onTap: onSelected,
            child: Padding(
              padding: compact
                  ? const EdgeInsets.fromLTRB(7, 7, 7, 7)
                  : const EdgeInsets.fromLTRB(10, 10, 10, 5),
              child: Column(
                children: [
                  Expanded(
                    child: OverflowBox(
                      alignment: Alignment.topCenter,
                      minWidth: 0,
                      minHeight: 0,
                      maxWidth: previewSize,
                      maxHeight: previewSize,
                      child: SizedBox.square(
                        dimension: previewSize,
                        child: _ItemPreview(
                          item: item,
                          controller: controller,
                          size: previewSize,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 3 : 5),
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: StoreVisualTokens.purpleDark,
                      fontWeight: FontWeight.w700,
                      fontSize: compact ? 15 : 20,
                      shadows: const [StoreVisualTokens.textShadow],
                    ),
                  ),
                  SizedBox(height: compact ? 5 : 3),
                  _ItemActionButton(
                    item: item,
                    owned: owned,
                    equipped: equipped,
                    compact: compact,
                    width: actionButtonWidth,
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
  static const _coinAssetPath = 'assets/images/ui/coin_star_v1.png';

  const _ItemActionButton({
    required this.item,
    required this.owned,
    required this.equipped,
    required this.compact,
    required this.width,
    required this.onPressed,
  });

  final ShopItem item;
  final bool owned;
  final bool equipped;
  final bool compact;
  final double width;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isPurchase = !owned;
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

    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: width,
        height: compact ? 30 : 32,
        child: Semantics(
          button: true,
          enabled: onPressed != null,
          label: '$label ${item.name}',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey('store_action_${item.id}'),
              borderRadius: BorderRadius.circular(18),
              onTap: onPressed,
              child: StoreItemActionButtonFrame(
                isPrice: isPurchase,
                child: Padding(
                  padding: compact
                      ? const EdgeInsets.fromLTRB(6, 3, 6, 5)
                      : const EdgeInsets.fromLTRB(8, 4, 8, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isPurchase) ...[
                        Icon(
                          equipped
                              ? Icons.check_circle_rounded
                              : Icons.checkroom_rounded,
                          color: equipped
                              ? const Color(0xFFB8F27E)
                              : foreground,
                          size: compact ? 16 : 18,
                        ),
                        SizedBox(width: compact ? 3 : 5),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: foreground,
                            fontWeight: FontWeight.w700,
                            fontSize: compact ? 12 : 15,
                            height: 1,
                            shadows: const [StoreVisualTokens.textShadow],
                          ),
                        ),
                      ),
                      if (isPurchase && item.price > 0) ...[
                        SizedBox(width: compact ? 3 : 5),
                        Image.asset(
                          _coinAssetPath,
                          key: const ValueKey('store_item_price_coin_asset'),
                          width: compact ? 18 : 20,
                          height: compact ? 18 : 20,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          excludeFromSemantics: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemPreview extends StatelessWidget {
  const _ItemPreview({
    required this.item,
    required this.controller,
    required this.size,
  });

  final ShopItem item;
  final StoreController controller;
  final double size;

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
        ? SizedBox.square(dimension: size)
        : Transform.translate(
            offset: const Offset(0, -8),
            child: SizedBox.square(
              dimension: size,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: const Alignment(0, 0.72),
                    child: _NtiContactShadow(width: size * 0.58),
                  ),
                  Positioned.fill(
                    child: OverflowBox(
                      minWidth: 0,
                      minHeight: 0,
                      maxWidth: size,
                      maxHeight: size,
                      child: NtiStaticPreview(outfit: outfit, size: size),
                    ),
                  ),
                ],
              ),
            ),
          );
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
