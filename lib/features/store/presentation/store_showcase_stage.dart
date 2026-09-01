import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/customization/domain/nti_outfit.dart';
import 'package:flutter_application_1/features/customization/presentation/animated_nti_preview.dart';
import 'package:flutter_application_1/features/store/presentation/store_showcase_platform.dart';
import 'package:flutter_application_1/features/store/presentation/store_showcase_room.dart';

class StoreShowcaseStage extends StatelessWidget {
  const StoreShowcaseStage({
    required this.outfit,
    required this.message,
    required this.foregroundHeight,
    super.key,
  });

  final NtiOutfit outfit;
  final String message;
  final double foregroundHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stageHeight = math.min(foregroundHeight, constraints.maxHeight);
        final platformWidth = math.min(
          math.min(constraints.maxWidth * 0.58, 520.0),
          stageHeight * 1.45,
        );
        final platformHeight =
            platformWidth / StoreShowcasePlatform.aspectRatio;
        final rawNtiSize = math.min(
          270.0,
          math.min(stageHeight * 0.96, platformWidth * 0.82),
        );
        final platformBottom = math.max(4.0, stageHeight * 0.03);
        final anchoredNtiLimit =
            (stageHeight - platformBottom - platformHeight * 0.66) / 0.90;
        final ntiSize = math.min(rawNtiSize, math.max(0.0, anchoredNtiLimit));
        final ntiBottom = math.max(
          0.0,
          platformBottom + platformHeight * 0.66 - ntiSize * 0.10,
        );
        final contactShadowBottom = platformBottom + platformHeight * 0.65;

        return Stack(
          key: const ValueKey('store_showcase_stage'),
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            const Positioned.fill(child: StoreShowcaseRoom()),
            Positioned(
              key: const ValueKey('store_showcase_platform_anchor'),
              left: (constraints.maxWidth - platformWidth) / 2,
              bottom: constraints.maxHeight - stageHeight + platformBottom,
              width: platformWidth,
              height: platformHeight,
              child: const StoreShowcasePlatform(),
            ),
            Positioned(
              left: (constraints.maxWidth - ntiSize * 0.55) / 2,
              bottom: constraints.maxHeight - stageHeight + contactShadowBottom,
              width: ntiSize * 0.55,
              height: math.max(7.0, ntiSize * 0.065),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0x3D382146),
                  borderRadius: BorderRadius.all(Radius.elliptical(999, 80)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x24382146),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              key: const ValueKey('store_showcase_nti_anchor'),
              left: (constraints.maxWidth - ntiSize) / 2,
              bottom: constraints.maxHeight - stageHeight + ntiBottom,
              width: ntiSize,
              height: ntiSize,
              child: AnimatedNtiPreview(
                outfit: outfit,
                message: message,
                size: ntiSize,
              ),
            ),
          ],
        );
      },
    );
  }
}
