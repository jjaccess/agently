
enum TaskStatus {
  open,
  inProgress,
  onHold,
  done,
  cancelled,
}

extension TaskStatusX on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.open:
        return "Abierta";
      case TaskStatus.inProgress:
        return "En progreso";
      case TaskStatus.onHold:
        return "En espera";
      case TaskStatus.done:
        return "Cerrada";
      case TaskStatus.cancelled:
        return "Cancelada";
    }
  }

  static TaskStatus fromIndex(int index) {
    return TaskStatus.values[index];
  }
}
