// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:json_annotation/json_annotation.dart';
part 'tile.g.dart';

@JsonSerializable(anyMap: true)
class Tile {
  final String id;
  final int value;
  final int index;
  final int? nextIndex;
  final bool merged;

  Tile(
    this.id,
    this.value,
    this.index, {
    this.nextIndex,
    this.merged = false,
  });

  @override
  String toString() {
    return 'Tile(id: $id, value: $value, index: $index, nextIndex: $nextIndex, merged: $merged)';
  }

  Tile copyWith({
    String? id,
    int? value,
    int? index,
    int? nextIndex,
    bool? merged,
  }) {
    return Tile(
      id ?? this.id,
      value ?? this.value,
      index ?? this.index,
      nextIndex: nextIndex ?? this.nextIndex,
      merged: merged ?? this.merged,
    );
  }

  double getTop(double size) {
    var i = ((index + 1) / 4).ceil();
    return ((i - 1) * size) + (12.0 * i);
  }

  double getLeft(double size) {
    var i = (index - (((index + 1) / 4).ceil() * 4 - 4));
    return (i * size) + (12.0 * (i + 1));
  }

  double? getNextTop(double size) {
    if (nextIndex == null) return null;
    var i = ((nextIndex! + 1) / 4).ceil();
    return ((i - 1) * size) + (12.0 * i);
  }

  double? getNextLeft(double size) {
    if (nextIndex == null) return null;
    var i = (nextIndex! - (((nextIndex! + 1) / 4).ceil() * 4 - 4));
    return (i * size) + (12.0 * (i + 1));
  }

  factory Tile.fromJson(Map<String, dynamic> json) => _$TileFromJson(json);

  Map<String, dynamic> toJson() => _$TileToJson(this);

  // Map<String, dynamic> toMap() {
  //   return <String, dynamic>{
  //     'id': id,
  //     'value': value,
  //     'index': index,
  //     'nextIndex': nextIndex,
  //     'merged': merged,
  //   };
  // }

  // factory Tile.fromMap(Map<String, dynamic> map) {
  //   return Tile(
  //     map['id'] as String,
  //     map['value'] as int,
  //     map['index'] as int,
  //     nextIndex: map['nextIndex'] != null ? map['nextIndex'] as int : null,
  //     merged: map['merged'] as bool,
  //   );
  // }

  // String toJson() => json.encode(toMap());

  // factory Tile.fromJson(String source) =>
  //     Tile.fromMap(json.decode(source) as Map<String, dynamic>);
}
