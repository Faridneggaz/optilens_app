class TaskSummary {
  const TaskSummary({
    required this.totalItems,
    required this.openCount,
    required this.closedCount,
    required this.overdueCount,
  });

  final int totalItems;
  final int openCount;
  final int closedCount;
  final int overdueCount;
}

class TodoTask {
  TodoTask({
    required this.name,
    required this.description,
    required this.status,
    required this.priority,
    required this.date,
    required this.allocatedTo,
    required this.assignedBy,
    required this.referenceType,
    required this.referenceName,
    required this.creation,
    required this.modified,
  });

  final String name;
  String description;
  String status;
  String priority;
  String date;
  String allocatedTo;
  String assignedBy;
  String referenceType;
  String referenceName;
  String creation;
  String modified;

  bool get isOpen {
    final s = status.toLowerCase().trim();
    return s == 'open' || s == 'opened' || s.isEmpty;
  }

  bool get isClosed {
    final s = status.toLowerCase().trim();
    return s == 'closed' || s == 'cancelled' || s == 'canceled';
  }

  bool get isOverdue {
    if (!isOpen || date.isEmpty) return false;
    final due = DateTime.tryParse(date);
    if (due == null) return false;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final dueDate = DateTime(due.year, due.month, due.day);
    return dueDate.isBefore(todayDate);
  }

  bool get hasReference =>
      referenceType.trim().isNotEmpty && referenceName.trim().isNotEmpty;
}

class TaskListResponse {
  const TaskListResponse({
    required this.user,
    required this.date,
    required this.status,
    required this.summary,
    required this.tasks,
    this.canCreate = false,
    this.allocatedTo = '',
    this.isSearch = false,
    this.limit = 20,
    this.offset = 0,
    this.hasMore = false,
  });

  final String user;
  final String date;
  final String status;
  final TaskSummary summary;
  final List<TodoTask> tasks;
  final bool canCreate;
  final String allocatedTo;
  final bool isSearch;
  final int limit;
  final int offset;
  final bool hasMore;
}

class TaskDetailResponse {
  const TaskDetailResponse({
    required this.task,
    required this.canWrite,
  });

  final TodoTask task;
  final bool canWrite;
}

/// ERPNext User selectable for ToDo.allocated_to (email = User.name).
class AssignableUser {
  const AssignableUser({
    required this.email,
    required this.fullName,
  });

  /// User.name / email sent as allocated_to.
  final String email;
  final String fullName;

  String get displayName =>
      fullName.trim().isNotEmpty ? fullName.trim() : email;

  String get subtitle {
    if (fullName.trim().isEmpty ||
        fullName.trim().toLowerCase() == email.toLowerCase()) {
      return email;
    }
    return email;
  }
}
