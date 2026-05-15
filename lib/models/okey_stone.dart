class OkeyStone {
  final String path;
  final String id;
  final int value;
  final String color;
  bool isRevealed;

  OkeyStone({
    required this.path,
    required this.id,
    required this.value,
    required this.color,
    this.isRevealed = false,
  });

  /// Sunucudan gelen JSON verisinden OkeyStone oluştur
  factory OkeyStone.fromJson(Map<String, dynamic> json) {
    final color = json['color'] as String;
    final value = json['value'] as int;
    final id = json['id'] as String;
    final String path;
    if (color == 'joker') {
      path = 'assets/images/sahte_okey.png';
    } else {
      path = 'assets/images/${color}_$value.png';
    }
    return OkeyStone(
      path: path,
      id: id,
      value: value,
      color: color,
      isRevealed: json['isRevealed'] ?? false,
    );
  }

  /// Sunucuya göndermek için JSON'a dönüştür
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'value': value,
      'color': color,
      'isRevealed': isRevealed,
    };
  }
}