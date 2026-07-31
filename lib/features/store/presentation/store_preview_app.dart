import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/customization/domain/pet_skin.dart';
import 'package:flutter_application_1/features/customization/domain/theme_option.dart';
import 'package:flutter_application_1/features/store/application/store_controller.dart';
import 'package:flutter_application_1/features/store/domain/shop_item.dart';

ThemeData storeThemeFrom(ThemeOption option) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Color(option.accentColorValue),
      brightness: option.id == 'techno' ? Brightness.dark : Brightness.light,
    ),
    scaffoldBackgroundColor: Color(option.backgroundColorValue),
    cardColor: Color(option.surfaceColorValue),
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

  StoreController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    final visibleItems = _selectedPage == 0
        ? controller.catalog
        : controller.catalog.where(controller.isOwned).toList();

    return Scaffold(
      appBar: AppBar(
        leading: widget.onClose == null
            ? null
            : IconButton(
                key: const ValueKey('store_close_button'),
                tooltip: 'Cerrar tienda',
                onPressed: widget.onClose,
                icon: const Icon(Icons.close),
              ),
        title: const Text('Personalización'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              avatar: const Icon(Icons.monetization_on_outlined),
              label: Text('${controller.coins} monedas'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _PetPreview(skin: controller.selectedSkin),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    icon: Icon(Icons.storefront_outlined),
                    label: Text('Tienda'),
                  ),
                  ButtonSegment(
                    value: 1,
                    icon: Icon(Icons.inventory_2_outlined),
                    label: Text('Inventario'),
                  ),
                ],
                selected: {_selectedPage},
                onSelectionChanged: (selection) {
                  setState(() => _selectedPage = selection.first);
                },
              ),
            ),
            Expanded(
              child: visibleItems.isEmpty
                  ? const Center(child: Text('Todavía no tienes artículos.'))
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 260,
                            mainAxisExtent: 250,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: visibleItems.length,
                      itemBuilder: (context, index) {
                        final item = visibleItems[index];
                        return _StoreItemCard(
                          item: item,
                          controller: controller,
                          onAction: () => _handleItemAction(item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleItemAction(ShopItem item) async {
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
      PurchaseResult.success => 'Compra realizada.',
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

class _PetPreview extends StatelessWidget {
  const _PetPreview({required this.skin});

  final PetSkin skin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Card(
        child: SizedBox(
          height: 150,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 86,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color(skin.previewColorValue),
                  borderRadius: BorderRadius.circular(42),
                  boxShadow: const [
                    BoxShadow(blurRadius: 12, color: Colors.black26),
                  ],
                ),
                child: const Text(
                  '•ᴗ•',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Skin equipada: ${skin.displayName}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
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
    required this.onAction,
  });

  final ShopItem item;
  final StoreController controller;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final owned = controller.isOwned(item);
    final equipped = controller.isEquipped(item);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.center,
              child: _ItemPreview(item: item, controller: controller),
            ),
            const SizedBox(height: 12),
            Text(item.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                item.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: equipped ? null : onAction,
                icon: Icon(
                  equipped
                      ? Icons.check_circle
                      : owned
                      ? Icons.checkroom
                      : Icons.monetization_on_outlined,
                ),
                label: Text(
                  equipped
                      ? 'Equipado'
                      : owned
                      ? 'Equipar'
                      : '${item.price} monedas',
                ),
              ),
            ),
          ],
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
      final theme = controller.themes
          .where((option) => option.id == item.customizationId)
          .firstOrNull;
      return CircleAvatar(
        radius: 34,
        backgroundColor: Color(theme?.backgroundColorValue ?? 0xFFEEEEEE),
        child: Icon(
          Icons.palette_outlined,
          color: Color(theme?.accentColorValue ?? 0xFF7E57C2),
          size: 34,
        ),
      );
    }

    final skin = controller.skins
        .where((option) => option.id == item.customizationId)
        .firstOrNull;
    return CircleAvatar(
      radius: 34,
      backgroundColor: Color(skin?.previewColorValue ?? 0xFF9B59B6),
      child: const Text(
        '•ᴗ•',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }
}
