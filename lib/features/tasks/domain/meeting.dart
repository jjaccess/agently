class Meeting {
  final String id;
  final String name;
  final DateTime date;
  final String description;

  Meeting({
    required this.id,
    required this.name,
    required this.date,
    this.description = '',
  });

  // --- PARA SQLITE (toMap) ---
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name':
          name, // Usamos 'name' para que coincida con el SQL que escribimos antes
      'description': description,
      'date': date.toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(), // Útil para ordenar
    };
  }

  // --- DESDE SQLITE (fromMap) ---
  factory Meeting.fromMap(Map<String, dynamic> map) {
    return Meeting(
      id: map['id'] as String,
      name:
          map['name']
              as String, // Mapeamos 'name' de la DB a 'title' del modelo
      date: DateTime.parse(map['date'] as String),
      description: map['description'] as String? ?? '',
    );
  }

  // Si aún usas JSON para backups, mantén estos:
  Map<String, dynamic> toJson() => toMap();
  factory Meeting.fromJson(Map<String, dynamic> json) => Meeting.fromMap(json);

  Meeting copyWith({
    String? id,
    String? name,
    DateTime? date,
    String? description,
  }) {
    return Meeting(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      description: description ?? this.description,
    );
  }
}
