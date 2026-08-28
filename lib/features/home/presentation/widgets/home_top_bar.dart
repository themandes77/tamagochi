import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/home/presentation/widgets/segmented_status_bar.dart';
import 'package:flutter_application_1/theme/app_ui_assets.dart';

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    required this.coins,
    required this.health,
    required this.onStorePressed,
    required this.onPausePressed,
    required this.storeEnabled,
    super.key,
  });

  final int coins;
  final double health;
  final VoidCallback onStorePressed;
  final VoidCallback onPausePressed;
  final bool storeEnabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _CoinCounter(coins: coins),
          const Spacer(),
          _HealthIndicator(health: health),
          const Spacer(),
          _TopImageButton(
            asset: AppUiAssets.storeIcon,
            semanticLabel: 'Tienda',
            enabled: storeEnabled,
            onPressed: onStorePressed,
          ),
          const SizedBox(width: 5),
          _TopImageButton(
            asset: AppUiAssets.pauseIcon,
            semanticLabel: 'Pausa',
            enabled: true,
            onPressed: onPausePressed,
          ),
        ],
      ),
    );
  }
}

class _CoinCounter extends StatelessWidget {
  const _CoinCounter({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      constraints: const BoxConstraints(minWidth: 76, maxWidth: 94),
      padding: const EdgeInsets.fromLTRB(4, 3, 9, 3),
      decoration: BoxDecoration(
        color: const Color(0xFF8D53AF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0B8F0), width: 1.5),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x38000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Image.asset(
            AppUiAssets.coinIcon,
            width: 29,
            height: 29,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$coins',
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthIndicator extends StatelessWidget {
  const _HealthIndicator({required this.health});

  final double health;

  @override
  Widget build(BuildContext context) {
    final normalized = health.clamp(0.0, 10.0).toDouble();
    return Container(
      width: 78,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xEFFFF7F0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Image.asset(
            AppUiAssets.healthIcon,
            width: 21,
            height: 21,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: SegmentedStatusBar(
              value: normalized / 10.0,
              color: _healthColor(normalized),
              height: 8,
            ),
          ),
        ],
      ),
    );
  }

  Color _healthColor(double value) {
    const green = Color(0xFF5BCB75);
    const orange = Color(0xFFF2A65A);
    const red = Color(0xFFE75A5A);

    if (value >= 5.0) {
      return Color.lerp(orange, green, (value - 5.0) / 5.0)!;
    }
    if (value >= 3.0) {
      return Color.lerp(red, orange, (value - 3.0) / 2.0)!;
    }
    return red;
  }
}

class _TopImageButton extends StatelessWidget {
  const _TopImageButton({
    required this.asset,
    required this.semanticLabel,
    required this.enabled,
    required this.onPressed,
  });

  final String asset;
  final String semanticLabel;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: InkResponse(
          onTap: enabled ? onPressed : null,
          radius: 24,
          child: SizedBox.square(
            dimension: 40,
            child: Padding(
              padding: const EdgeInsets.all(1),
              child: Image.asset(asset, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
