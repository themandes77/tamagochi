import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/home/presentation/widgets/segmented_status_bar.dart';

class NeedStatusCard extends StatelessWidget {
  const NeedStatusCard({
    required this.label,
    required this.value,
    required this.color,
    required this.iconAsset,
    super.key,
  });

  final String label;
  final double value;
  final Color color;
  final String iconAsset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / 78).clamp(0.84, 1.06).toDouble();

        return Align(
          alignment: Alignment.center,
          child: SizedBox(
            height: (34 * scale).clamp(31.0, 36.0).toDouble(),
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF8E9D8).withValues(alpha: 0.98),
                borderRadius: BorderRadius.circular(11 * scale),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.90),
                  width: 1.25,
                ),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 2.5,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 4 * scale,
                  vertical: 1,
                ),
                child: Row(
                  children: <Widget>[
                    SizedBox.square(
                      dimension: 18 * scale,
                      child: Image.asset(iconAsset, fit: BoxFit.contain),
                    ),
                    SizedBox(width: 3 * scale),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(left: 1 * scale),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                label.toUpperCase(),
                                maxLines: 1,
                                style: TextStyle(
                                  color: const Color(0xFF532F3C),
                                  fontSize: 8 * scale,
                                  fontWeight: FontWeight.w900,
                                  height: 0.95,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 2.5 * scale),
                          SegmentedStatusBar(
                            value: value.clamp(0.0, 10.0) / 10.0,
                            color: color,
                            height: 6 * scale,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
