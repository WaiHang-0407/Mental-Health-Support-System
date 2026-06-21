// models/patient.dart
class PatientModel {
  final String id;
  final String? name;
  final String? gender;
  final DateTime? dob;
  final String? phoneno;
  final String? condition;
  final String? favAnimal;
  final String? favActivity;
  final String? avatarUrl; // 👈 added

  PatientModel({
    required this.id,
    this.name,
    this.gender,
    this.dob,
    this.phoneno,
    this.condition,
    this.favAnimal,
    this.favActivity,
    this.avatarUrl,
  });

  factory PatientModel.fromMap(Map<String, dynamic> map) {
    return PatientModel(
      id: map['id'],
      name: map['name'],
      gender: map['gender'],
      dob: map['dob'] != null ? DateTime.parse(map['dob']) : null,
      phoneno: map['phoneno'],
      condition: map['condition'],
      favAnimal: map['fav_animal'],
      favActivity: map['fav_activity'],
      avatarUrl: map['avatar_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (name != null) 'name': name,
      if (gender != null) 'gender': gender,
      if (dob != null) 'dob': dob!.toIso8601String().split('T').first,
      if (phoneno != null) 'phoneno': phoneno,
      if (condition != null) 'condition': condition,
      if (favAnimal != null) 'fav_animal': favAnimal,
      if (favActivity != null) 'fav_activity': favActivity,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };
  }
}
