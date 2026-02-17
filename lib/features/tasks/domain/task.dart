import 'task_priority.dart';
import 'task_status.dart';

const List<String> taskCategories = [
  'General',
  'Infraestructura',
  'Seguridad',
  'Desarrollo',
  'Soporte',
  'Plataforma',
  'Telecomunicaciones',
];

class Task {
  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final String category;
  final String? assignedTo;
  final List<String> tags;
  final List<String> attachments;
  final int? estimatedMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? dueDate;
  final int? reminderMinutesBefore;
  final String? meetingId; // <--- VÍNCULO CON EL COMITÉ
  final String? closingComment; // Comentario de cierre
  final List<String>? evidencePaths; // Rutas de las fotos/archivos
  final DateTime? completedAt;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.status = TaskStatus.open,
    this.priority = TaskPriority.medium,
    this.category = 'General',
    this.assignedTo,
    this.tags = const [],
    this.attachments = const [],
    this.estimatedMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.dueDate,
    this.reminderMinutesBefore,
    this.meetingId, // <--- AÑADIDO AL CONSTRUCTOR
    this.closingComment, // Agrégalo al constructor
    this.evidencePaths, // Agrégalo al constructor
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Task copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    String? category,
    String? assignedTo,
    List<String>? tags,
    List<String>? attachments,
    int? estimatedMinutes,
    DateTime? dueDate,
    int? reminderMinutesBefore,
    String? meetingId, // <--- AÑADIDO AL COPYWITH
    DateTime? updatedAt,
    String? closingComment,
    List<String>? evidencePaths,
    DateTime? completedAt,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      assignedTo: assignedTo ?? this.assignedTo,
      tags: tags ?? this.tags,
      attachments: attachments ?? this.attachments,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      dueDate: dueDate ?? this.dueDate,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      meetingId: meetingId ?? this.meetingId,
      closingComment: closingComment ?? this.closingComment,
      evidencePaths: evidencePaths ?? this.evidencePaths,
      completedAt: completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'status': status.name,
    'priority': priority.name,
    'category': category,
    'assignedTo': assignedTo,
    'tags': tags,
    'attachments': attachments,
    'estimatedMinutes': estimatedMinutes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'dueDate': dueDate?.toIso8601String(),
    'reminderMinutesBefore': reminderMinutesBefore,
    'meetingId': meetingId, // <--- AÑADIDO AL JSON
    'closingComment': closingComment, // <--- AÑADIDO AL JSON
    'evidencePaths': evidencePaths, // <--- AÑADIDO AL JSON
  };

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'] ?? 'Sin título',
      description: json['description'] ?? '',
      status: TaskStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TaskStatus.open,
      ),
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      category: json['category'] ?? 'General',
      assignedTo: json['assignedTo'] ?? '',
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'])
          : [],
      estimatedMinutes: json['estimatedMinutes'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      reminderMinutesBefore: json['reminderMinutesBefore'],
      meetingId: json['meetingId']?.toString(),
      closingComment: json['closingComment'],
      evidencePaths: json['evidencePaths'] != null
          ? List<String>.from(json['evidencePaths'])
          : [],
    );
  }

  // Convierte el objeto Task a un Mapa para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.name,
      'priority': priority.name,
      'category': category,
      'assignedTo': assignedTo,
      'dueDate': dueDate?.toIso8601String(),
      'meetingId': meetingId,
      'reminderMinutesBefore': reminderMinutesBefore,
      'closingComment': closingComment,
      // IMPORTANTE: SQLite no guarda listas, las unimos con comas
      'evidencePaths': evidencePaths?.join(','),
      'tags': tags.join(','),
      'attachments': attachments.join(','),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Crea una Task desde los datos de SQLite
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'] ?? '',
      status: TaskStatus.values.byName(map['status'] ?? 'open'),
      priority: TaskPriority.values.byName(map['priority'] ?? 'medium'),
      category: map['category'] ?? 'General',
      assignedTo: map['assignedTo'],
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      meetingId: map['meetingId'],
      reminderMinutesBefore: map['reminderMinutesBefore'],
      closingComment: map['closingComment'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
      // Convertimos los Strings de vuelta a Listas
      evidencePaths:
          (map['evidencePaths'] as String?)
              ?.split(',')
              .where((s) => s.isNotEmpty)
              .toList() ??
          [],
      tags:
          (map['tags'] as String?)
              ?.split(',')
              .where((s) => s.isNotEmpty)
              .toList() ??
          [],
      attachments:
          (map['attachments'] as String?)
              ?.split(',')
              .where((s) => s.isNotEmpty)
              .toList() ??
          [],
    );
  }
}
