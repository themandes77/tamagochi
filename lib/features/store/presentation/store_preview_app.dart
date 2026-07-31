import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/customization/domain/nti_outfit.dart';
import 'package:flutter_application_1/features/customization/domain/theme_option.dart';
import 'package:flutter_application_1/features/customization/presentation/animated_nti_preview.dart';
import 'package:flutter_application_1/features/store/application/store_controller.dart';
import 'package:flutter_application_1/features/store/domain/shop_item.dart';

ThemeData storeThemeFrom(ThemeOption option) {
  const primary = Color(0xFF7446B8);
  const surface = Color(0xFFFFF9F0);

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      surface: surface,
    ),
    scaffoldBackgroundColor: const Color(0xFFF1E7FA),
    cardTheme: const CardThemeData(
      color: surface,
      elevation: 2,
      shadowColor: Color(0x337446B8),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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

  @override
  Widget build(BuildContext context) {
    final visibleItems = controller
        .itemsFor(_selectedKind)
        .where((item) => _selectedPage == 0 || controller.isOwned(item))
        .toList(growable: false);
    final previewItem = _findPreviewItem();
    final previewOutfit = _outfitFor(previewItem) ?? controller.selectedOutfit;
    final previewTheme = _themeFor(previewItem) ?? controller.selectedTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1E7FA),
        leading: widget.onClose == null
            ? null
            : IconButton.filledTonal(
                key: const ValueKey('store_close_button'),
                tooltip: 'Cerrar tienda',
                onPressed: widget.onClose,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
        title: const Text(
          'Tienda',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _CoinBalance(coins: controller.coins),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: _CustomizationPreview(
                outfit: previewOutfit,
                theme: previewTheme,
                message: previewItem == null
                    ? '¡Elige un estilo!'
                    : '¡${previewItem.name} me queda genial!',
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(
                          value: 0,
                          icon: Icon(Icons.storefront_rounded),
                          label: Text('Tienda'),
                        ),
                        ButtonSegment(
                          value: 1,
                          icon: Icon(Icons.inventory_2_rounded),
                          label: Text('Mis artículos'),
                        ),
                      ],
                      selected: {_selectedPage},
                      onSelectionChanged: (selection) {
                        setState(() {
                          _selectedPage = selection.first;
                          _previewItemId = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: SegmentedButton<ShopItemKind>(
                segments: const [
                  ButtonSegment(
                    value: ShopItemKind.outfit,
                    icon: Icon(Icons.checkroom_rounded),
                    label: Text('Trajes'),
                  ),
                  ButtonSegment(
                    value: ShopItemKind.theme,
                    icon: Icon(Icons.wallpaper_rounded),
                    label: Text('Fondos'),
                  ),
                ],
                selected: {_selectedKind},
                onSelectionChanged: (selection) {
                  setState(() {
                    _selectedKind = selection.first;
                    _previewItemId = null;
                  });
                },
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: visibleItems.isEmpty
                    ? const Center(
                        key: ValueKey('empty_inventory'),
                        child: Text('Todavía no tienes artículos.'),
                      )
                    : GridView.builder(
                        key: ValueKey('${_selectedPage}_${_selectedKind.name}'),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 250,
                              mainAxisExtent: 238,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: visibleItems.length,
                        itemBuilder: (context, index) {
                          final item = visibleItems[index];
                          return _StoreItemCard(
                            item: item,
                            controller: controller,
                            selected: item.id == _previewItemId,
                            onSelected: () {
                              setState(() => _previewItemId = item.id);
                            },
                            onAction: () => _handleItemAction(item),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
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
      ..showSnackBar(SnackBar(content: Text(message)));
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
    return Container(
      height: 208,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFB78CDF), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x267446B8),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: _ThemeBackdrop(key: ValueKey(theme.id), theme: theme),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0x660F0820)],
                stops: [0.52, 1],
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.18),
            child: AnimatedNtiPreview(
              outfit: outfit,
              message: message,
              size: 174,
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Container(
                key: ValueKey(message),
                constraints: const BoxConstraints(maxWidth: 190),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xF2FFF9F0),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF7446B8)),
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF352147),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xCC352147),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '${outfit.displayName} · ${theme.displayName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
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
          colors: [Color(0xFFFFF8E8), Color(0xFFDCC8F2)],
        ),
      ),
      child: Center(
        child: Icon(Icons.auto_awesome_rounded, color: Color(0x557446B8)),
      ),
    );
  }
}

class _CoinBalance extends StatelessWidget {
  const _CoinBalance({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4C2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0AD31)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.monetization_on_rounded,
            color: Color(0xFFD28A13),
            size: 20,
          ),
          const SizedBox(width: 5),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
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
                color: Color(0xFF4E3512),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreItemCard extends StatelessWidget {
  const _StoreItemCard({
    required this.item,
    required this.controller,
    required this.selected,
    required this.onSelected,
    required this.onAction,
  });

  final ShopItem item;
  final StoreController controller;
  final bool selected;
  final VoidCallback onSelected;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final owned = controller.isOwned(item);
    final equipped = controller.isEquipped(item);

    return AnimatedScale(
      scale: selected ? 1.0 : 0.985,
      duration: const Duration(milliseconds: 140),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: selected ? const Color(0xFF7446B8) : const Color(0xFFD8C4EA),
            width: selected ? 3 : 1.5,
          ),
        ),
        child: InkWell(
          key: ValueKey('store_item_${item.id}'),
          onTap: onSelected,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: _ItemPreview(item: item, controller: controller),
                ),
                const SizedBox(height: 8),
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 7),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: equipped ? null : onAction,
                    icon: Icon(
                      equipped
                          ? Icons.check_circle_rounded
                          : owned
                          ? Icons.checkroom_rounded
                          : Icons.monetization_on_rounded,
                    ),
                    label: Text(
                      equipped
                          ? 'Equipado'
                          : owned
                          ? 'Equipar'
                          : item.price == 0
                          ? 'Gratis'
                          : '${item.price}',
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
      return Container(
        width: 92,
        height: 82,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Color(theme?.backgroundColorValue ?? 0xFFEEEEEE),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD8C4EA)),
        ),
        child: assetPath == null
            ? const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF7446B8),
                size: 34,
              )
            : Image.asset(assetPath, fit: BoxFit.cover),
      );
    }

    final outfit = _findOutfit();
    return outfit == null
        ? const SizedBox.square(dimension: 82)
        : NtiStaticPreview(outfit: outfit, size: 82);
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
