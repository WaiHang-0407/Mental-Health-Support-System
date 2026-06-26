class Affirmation {
  const Affirmation({
    required this.id,
    required this.text,
    required this.createdAt,
    this.createdBy,
    this.isActive = true,
  });

  final String id;
  final String text;
  final String? createdBy;
  final bool isActive;
  final DateTime? createdAt;

  factory Affirmation.fromJson(Map<String, dynamic> json) {
    return Affirmation(
      id: json['id'] as String,
      text: json['text'] as String? ?? '',
      createdBy: json['created_by'] as String?,
      isActive: _parseBool(json['is_active']),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return true;
  }
}
