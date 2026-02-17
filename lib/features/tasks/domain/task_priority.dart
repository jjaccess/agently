
enum TaskPriority {
  low,
  medium,
  high,
  critical,
}

extension TaskPriorityX on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low:
        return "Baja";
      case TaskPriority.medium:
        return "Media";
      case TaskPriority.high:
        return "Alta";
      case TaskPriority.critical:
        return "Crítica";
    }
  }

  static TaskPriority fromIndex(int index) {
    return TaskPriority.values[index];
  }
}
