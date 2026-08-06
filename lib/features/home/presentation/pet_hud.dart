import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/pet/domain/pet_state.dart';

class PetHud extends StatelessWidget {
  const PetHud({
    required this.state,
    required this.health,
    required this.expanded,
    required this.onToggle,
    super.key,
  });

  final PetState state;
  final double health;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _NeedIndicator(label: 'Salud', value: health),
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.topCenter,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 10,
                        childAspectRatio: 3.4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: <Widget>[
                          _NeedIndicator(
                            label: 'Saciedad',
                            value: state.hunger,
                          ),
                          _NeedIndicator(
                            label: 'Limpieza',
                            value: state.cleanliness,
                          ),
                          _NeedIndicator(
                            label: 'Energía',
                            value: state.energy,
                          ),
                          _NeedIndicator(
                            label: 'Diversión',
                            value: state.fun,
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeedIndicator extends StatelessWidget {
  const _NeedIndicator({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final normalized = (value / 10.0).clamp(0.0, 1.0).toDouble();
    final percent = (normalized * 100).round();

    return Semantics(
      label: '$label, $percent por ciento',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              const SizedBox(width: 6),
              Text('$percent%'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: normalized),
        ],
      ),
    );
  }
}
