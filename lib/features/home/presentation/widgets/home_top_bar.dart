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
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / 360).clamp(0.88, 1.05).toDouble();
        final buttonSize = 40 * scale;
        final gap = (5 * scale).clamp(3.0, 6.0).toDouble();

        return SizedBox(
          height: 42 * scale,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _CoinCounter(coins: coins, scale: scale),
              const Spacer(),
              _HealthIndicator(health: health, scale: scale),
              const Spacer(),
              _TopImageButton(
                asset: AppUiAssets.storeIcon,
                semanticLabel: 'Tienda',
                enabled: storeEnabled,
                onPressed: onStorePressed,
                size: buttonSize,
              ),
              SizedBox(width: gap),
              _TopImageButton(
                asset: AppUiAssets.pauseIcon,
                semanticLabel: 'Pausa',
                enabled: true,
                onPressed: onPausePressed,
                size: buttonSize,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CoinCounter extends StatelessWidget {
  const _CoinCounter({required this.coins, required this.scale});

  final int coins;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38 * scale,
      constraints: BoxConstraints(
        minWidth: 72 * scale,
        maxWidth: 96 * scale,
      ),
      padding: EdgeInsets.fromLTRB(4 * scale, 3 * scale, 9 * scale, 3 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFF8D53AF),
        borderRadius: BorderRadius.circular(20 * scale),
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
            width: 29 * scale,
            height: 29 * scale,
            fit: BoxFit.contain,
          ),
          SizedBox(width: 4 * scale),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$coins',
                maxLines: 1,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16 * scale,
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
  const _HealthIndicator({required this.health, required this.scale});

  final double health;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final normalized = health.clamp(0.0, 10.0).toDouble();
    return Container(
      width: 78 * scale,
      height: 36 * scale,
      padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 6 * scale),
      decoration: BoxDecoration(
        color: const Color(0xEFFFF7F0),
        borderRadius: BorderRadius.circular(18 * scale),
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
            width: 21 * scale,
            height: 21 * scale,
            fit: BoxFit.contain,
          ),
          SizedBox(width: 4 * scale),
          Expanded(
            child: SegmentedStatusBar(
              value: normalized / 10.0,
              color: _healthColor(normalized),
              height: 8 * scale,
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
    required this.size,
  });

  final String asset;
  final String semanticLabel;
  final bool enabled;
  final VoidCallback onPressed;
  final double size;

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
          radius: size * 0.6,
          child: SizedBox.square(
            dimension: size,
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
