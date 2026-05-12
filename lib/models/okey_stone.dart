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
}