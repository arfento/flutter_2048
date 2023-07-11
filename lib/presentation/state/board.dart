// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:math';

import 'package:flutter/src/services/raw_keyboard.dart';
import 'package:flutter_2048/data/models/tile.dart';
import 'package:flutter_2048/presentation/state/next_direction.dart';
import 'package:flutter_2048/presentation/state/round.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_2048/data/models/board.dart';
import 'package:flutter_swipe_detector/flutter_swipe_detector.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class BoardManager extends StateNotifier<Board> {
  final verticalOrder = [12, 8, 4, 0, 13, 9, 5, 1, 14, 10, 6, 2, 15, 11, 7, 3];

  final StateNotifierProviderRef ref;
  BoardManager(
    this.ref,
  ) : super(Board.newGame(0, [])) {
    //Load the last saved state or start a new game.
    load();
  }

  void load() async {
    //Access the box and get the first item at index 0
    //which will always be just one item of the Board model
    //and here we don't need to call fromJson function of the board model
    //in order to construct the Board model
    //instead the adapter we added earlier will do that automatically.
    var box = await Hive.openBox<Board>('boardBox');
    //If there is no save locally it will start a new game.
    state = box.get(0) ?? _newGame();
  }

  void newGame() {
    state = _newGame();
  }

  Board _newGame() {
    return Board.newGame(state.best + state.score, [random([])]);
  }

  Tile random(List<int> indexes) {
    var i = 0;
    var rng = Random();
    do {
      i = rng.nextInt(16);
    } while (indexes.contains(i));

    return Tile(Uuid().v4(), 2, i);
  }

  void merge() {
    List<Tile> tiles = [];
    var tileMoves = false;
    List<int> indexes = [];
    var score = state.score;

    for (var i = 0, size = state.tiles.length; i < size; i++) {
      var tile = state.tiles[i];
      var value = tile.value;
      var merged = false;

      if (i + 1 < size) {
        var next = state.tiles[i + 1];
        if (tile.nextIndex == next.nextIndex ||
            tile.index == next.nextIndex && tile.nextIndex == null) {
          value = tile.value + next.value;
          merged = true;
          score += tile.value;
          i += 1;
        }
      }

      if (merged || tile.nextIndex != null && tile.index != tile.nextIndex) {
        tileMoves = true;
      }

      tiles.add(
        tile.copyWith(
            index: tile.nextIndex ?? tile.index,
            nextIndex: null,
            value: value,
            merged: merged),
      );
      indexes.add(tiles.last.index);
    }

    if (tileMoves) {
      tiles.add(random(indexes));
    }
    state = state.copyWith(score: score, tiles: tiles);
  }

  void _endRound() {
    var gameOver = true, gameWon = false;
    List<Tile> tiles = [];

    if (state.tiles.length == 16) {
      state.tiles.sort((a, b) {
        return a.index.compareTo(b.index);
      });

      //If there is no more empty place on the board
      for (var i = 0, size = state.tiles.length; i < size; i++) {
        var tile = state.tiles[i];

        //If there is a tile with 2048 then the game is won.
        if (tile.value == 2048) {
          gameWon = true;
        }

        var x = (i - (((i + 1) / 4).ceil() * 4 - 4));

        if (x > 0 && i - 1 >= 0) {
          //If tile can be merged with left tile then game is not lost.
          var left = state.tiles[i - 1];
          if (tile.value == left.value) {
            gameOver = false;
          }
        }

        if (x < 3 && i + 1 < size) {
          //If tile can be merged with right tile then game is not lost.
          var right = state.tiles[i + 1];
          if (tile.value == right.value) {
            gameOver = false;
          }
        }

        if (i - 4 >= 0) {
          //If tile can be merged with above tile then game is not lost.
          var top = state.tiles[i - 4];
          if (tile.value == top.value) {
            gameOver = false;
          }
        }

        if (i + 4 < size) {
          //If tile can be merged with the bellow tile then game is not lost.
          var bottom = state.tiles[i + 4];
          if (tile.value == bottom.value) {
            gameOver = false;
          }
        }
        //Set the tile merged: false
        tiles.add(tile.copyWith(merged: false));
      }
    } else {
      //There is still a place on the board to add a tile so the game is not lost.
      gameOver = false;
      for (var tile in state.tiles) {
        if (tile.value == 2048) {
          gameWon = true;
        }
        tiles.add(tile.copyWith(merged: false));
      }
    }
    state = state.copyWith(tiles: tiles, won: gameWon, over: gameOver);
  }

  bool endRound() {
    //End round.
    _endRound();
    ref.read(roundManager.notifier).end();

    //If player moved too fast before the current animation/transition finished, start the move for the next direction
    var nextDirection = ref.read(nextDirectionManager);
    if (nextDirection != null) {
      move(nextDirection);
      ref.read(nextDirectionManager.notifier).clear();
      return true;
    }
    return false;
  }

  bool onkey(RawKeyEvent event) {
    SwipeDirection? direction;
    if (event.isKeyPressed(LogicalKeyboardKey.arrowRight)) {
      direction = SwipeDirection.right;
    } else if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft)) {
      direction = SwipeDirection.left;
    } else if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
      direction = SwipeDirection.up;
    } else if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
      direction = SwipeDirection.down;
    }

    if (direction != null) {
      move(direction);
      return true;
    }
    return false;
  }

  bool move(SwipeDirection direction) {
    bool asc =
        direction == SwipeDirection.left || direction == SwipeDirection.up;
    bool vert =
        direction == SwipeDirection.up || direction == SwipeDirection.down;
    state.tiles.sort(
      (a, b) {
        return (asc ? 1 : -1) *
            (vert
                ? verticalOrder[a.index].compareTo(verticalOrder[b.index])
                : a.index.compareTo(b.index));
      },
    );
    List<Tile> tiles = [];

    for (var i = 0, size = state.tiles.length; i < size; i++) {
      var tile = state.tiles[i];
      tile = _calculate(tile, tiles, direction);
      tiles.add(tile);

      if (i + 1 < size) {
        var next = state.tiles[i + 1];
        if (tile.value == next.value) {
          var index = vert ? verticalOrder[tile.index] : tile.index;
          var nextIndex = vert ? verticalOrder[next.index] : next.index;
          if (_inRange(index, nextIndex)) {
            tiles.add(next.copyWith(nextIndex: tile.nextIndex));
            i += 1;
            continue;
          }
        }
      }
    }
    state = state.copyWith(tiles: tiles, undo: state);
    return true;
  }

  Future<void> save() async {
    //Here we don't need to call toJson function of the board model
    //in order to convert the data to json
    //instead the adapter we added earlier will do that automatically.
    var box = await Hive.openBox<Board>('boardBox');
    try {
      box.putAt(0, state);
    } catch (e) {
      box.add(state);
    }
  }

  Tile _calculate(Tile tile, List<Tile> tiles, SwipeDirection direction) {
    bool asc =
        direction == SwipeDirection.left || direction == SwipeDirection.up;
    bool vert =
        direction == SwipeDirection.up || direction == SwipeDirection.down;
    // Get the first index from the left in the row
    // Example: for left swipe that can be: 0, 4, 8, 12
    // for right swipe that can be: 3, 7, 11, 15
    // depending which row in the column in the board we need
    // let's say the title.index = 6 (which is the 3rd tile from the left and 2nd from right side, in the second row)
    // ceil means it will ALWAYS round up to the next largest integer
    // NOTE: don't confuse ceil it with floor or round as even if the value is 2.1 output would be 3.
    // ((6 + 1) / 4) = 1.75
    // Ceil(1.75) = 2
    // If it's ascending: 2 * 4 – 4 = 4, which is the first index from the left side in the second row
    // If it's descending: 2 * 4 – 1 = 7, which is the last index from the left side and first index from the right side in the second row
    // If user swipes vertically use the verticalOrder list to retrieve the up/down index else use the existing index

    int index = vert ? verticalOrder[tile.index] : tile.index;
    int nextIndex = ((index + 1) / 4).ceil() * 4 - (asc ? 4 : 1);

    // If the list of the new tiles to be rendered is not empty get the last tile
    // and if that tile is in the same row as the curren tile set the next index for the current tile to be after the last tile
    if (tiles.isNotEmpty) {
      var last = tiles.last;
      // If user swipes vertically use the verticalOrder list to retrieve the up/down index else use the existing index
      var lastIndex = last.nextIndex ?? last.index;
      lastIndex = vert ? verticalOrder[lastIndex] : lastIndex;
      if (_inRange(index, lastIndex)) {
        // If the order is ascending set the tile after the last processed tile
        // If the order is descending set the tile before the last processed tile
        nextIndex = lastIndex + (asc ? 1 : -1);
      }
    }
    // Return immutable copy of the current tile with the new next index
    // which can either be the top left index in the row or the last tile nextIndex/index + 1
    return tile.copyWith(
        nextIndex: vert ? verticalOrder.indexOf(nextIndex) : nextIndex);
  }

  bool _inRange(int index, int nextIndex) {
    return index < 4 && nextIndex < 4 ||
        index >= 4 && index < 8 && nextIndex >= 4 && nextIndex < 8 ||
        index >= 8 && index < 12 && nextIndex >= 8 && nextIndex < 12 ||
        index >= 12 && nextIndex >= 12;
  }

  void undo() {
    if (state.undo != null) {
      state = state.copyWith(
        score: state.undo!.score,
        best: state.undo!.best,
        tiles: state.undo!.tiles,
      );
    }
  }
}

final boardManager = StateNotifierProvider<BoardManager, Board>(
  (ref) => BoardManager(ref),
);
