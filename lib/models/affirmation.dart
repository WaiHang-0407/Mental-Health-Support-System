class Affirmation {
  final String id;
  final String text;

  const Affirmation({
    required this.id,
    required this.text,
  });

  factory Affirmation.fromMap(Map<String, dynamic> map) {
    return Affirmation(
      id: map['id'] as String,
      text: map['text'] as String,
    );
  }
}
