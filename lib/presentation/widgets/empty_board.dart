import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_2048/utils/colors.dart';

class EmptyBoardWidget extends StatelessWidget {
  const EmptyBoardWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = max(
        290.0,
        min((MediaQuery.of(context).size.shortestSide * 0.90).floorToDouble(),
            460.0));
    final sizePerTile = (size / 4).floorToDouble();
    final tileSize = sizePerTile - 12 - (12 / 4);
    final boardSize = sizePerTile * 4;
    return Container(
      width: boardSize,
      height: boardSize,
      decoration: BoxDecoration(
        color: boardColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(
        children: List.generate(16, (index) {
          var x = ((index + 1) / 4).ceil();
          var y = x - 1;
          var top = y * (tileSize) + (x * 12);
          var z = (index - (4 * y));
          var left = z * (tileSize) + ((z + 1) * 12);

          return Positioned(
            top: top,
            left: left,
            child: Container(
              width: tileSize,
              height: tileSize,
              decoration: BoxDecoration(
                color: emptyTileColor,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          );
        }),
      ),
    );
  }
}
