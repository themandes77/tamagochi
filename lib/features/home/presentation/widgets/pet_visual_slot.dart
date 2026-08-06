import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/home/presentation/widgets/pet_message_bubble.dart';

class PetVisualSlot extends StatelessWidget {
  const PetVisualSlot({
    required this.petVisual,
    this.message,
    super.key,
  });

  final Widget petVisual;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bubbleWidth = constraints.maxWidth.clamp(180.0, 300.0).toDouble();
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Positioned.fill(child: petVisual),
            if (message != null)
              Positioned(
                top: 8,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: bubbleWidth),
                  child: PetMessageBubble(message: message!),
                ),
              ),
          ],
        );
      },
    );
  }
}
