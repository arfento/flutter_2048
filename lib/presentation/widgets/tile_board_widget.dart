// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_2048/presentation/state/board.dart';
import 'package:flutter_2048/presentation/widgets/animated_tile.dart';
import 'package:flutter_2048/presentation/widgets/button.dart';
import 'package:flutter_2048/utils/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TileBoardWidget extends ConsumerWidget {
  final CurvedAnimation moveAnimation;
  final CurvedAnimation scaleAnimation;
  const TileBoardWidget({
    super.key,
    required this.moveAnimation,
    required this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(boardManager);
    final size = max(
        290.0,
        min((MediaQuery.of(context).size.shortestSide * 0.90).floorToDouble(),
            460.0));
    final sizePerTile = (size / 4).floorToDouble();
    final tileSize = sizePerTile - 12 - (12 / 4);
    final boardSize = sizePerTile * 4;

    return SizedBox(
      width: boardSize,
      height: boardSize,
      child: Stack(
        children: [
          ...List.generate(
            board.tiles.length,
            (index) {
              var tile = board.tiles[index];
              return AnimatedTile(
                key: ValueKey(tile.id),
                moveAnimation: moveAnimation,
                scaleAnimation: scaleAnimation,
                tile: tile,
                size: tileSize,
                //In order to optimize performances and prevent unneeded re-rendering the actual tile is passed as child to the AnimatedTile
                //as the tile won't change for the duration of the movement (apart from it's position)

                child: Container(
                  width: tileSize,
                  height: tileSize,
                  decoration: BoxDecoration(
                    color: tileColors[tile.value],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      "${tile.value}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: tile.value < 8 ? textColor : textColorWhite,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (board.over)
            Positioned.fill(
                child: Container(
              color: overlayColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    board.won ? "You Win" : "Game over!",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 64,
                      color: textColor,
                    ),
                  ),
                  ButtonWidget(
                    text: board.won ? "New Game" : "Try Again",
                    onPressed: () {
                      ref.read(boardManager.notifier).newGame();
                    },
                  )
                ],
              ),
            ))
        ],
      ),
    );
  }
}
