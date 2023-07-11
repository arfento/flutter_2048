import 'package:flutter_2048/data/models/board.dart';
import 'package:hive/hive.dart';

class BoardAdapter extends TypeAdapter<Board> {
  @override
  final typeId = 0;

  @override
  Board read(BinaryReader reader) {
    return Board.fromJson(Map<String, dynamic>.from(reader.read()));
  }

  @override
  void write(BinaryWriter writer, Board obj) {
    writer.write(obj.toJson());
  }
}
