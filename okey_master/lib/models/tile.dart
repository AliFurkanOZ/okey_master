import 'package:equatable/equatable.dart';

enum TileColor{yellow, blue, black, red}

class Tile extends Equatable{
  final String id;
  final TileColor color;
  final int? number; // null for fake okey
  final bool isFakeOkey;

  const Tile({
    required this.id,
    required this.color,
    required this.number,
    this.isFakeOkey = false,
  });

  Tile copyWith({ // copy state method for riverpod
    String? id,
    TileColor? color,
    int? number,
    bool? isFakeOkey,
  }) {
    return Tile(
      id: id ?? this.id,
      color: color ?? this.color,
      number: number ?? this.number,
      isFakeOkey: isFakeOkey ?? this.isFakeOkey,
    );
  }

  @override
  String toString() {
    if(isFakeOkey) return 'JOKER';
    return '${color.name.toUpperCase()}-$number';
  }

  @override
  List<Object?> get props => [id, color, number, isFakeOkey];
}