class DailyActivity {
  const DailyActivity({
    this.id,
    required this.title,
    required this.description,
    this.durationMinutes,
    this.isActive = true,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String title;
  final String description;
  final int? durationMinutes;
  final bool isActive;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory DailyActivity.fromJson(Map<String, dynamic> json) {
    return DailyActivity(
      id: json['id'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      durationMinutes: json['duration_minutes'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'title': title,
      'description': description,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (createdBy != null) 'created_by': createdBy,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'title': title,
      'description': description,
      'duration_minutes': durationMinutes,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
