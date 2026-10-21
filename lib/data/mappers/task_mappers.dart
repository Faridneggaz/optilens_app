import '../../domain/entities/task.dart';
import '../../utils/html_plain_text.dart';

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
bool _flag(dynamic value) => value == true || value == 1 || value == '1';
int _integer(dynamic value) => int.tryParse('${value ?? 0}') ?? 0;
List<String> _strings(dynamic value) =>
    value is List ? value.map((v) => v.toString()).toList() : const [];

class AssignableUserMapper {
  static List<AssignableUser> fromList(dynamic raw) {
    if (raw is! List) return const [];
    final users = <String, AssignableUser>{};
    for (final value in raw) {
      final row = _map(value);
      final email = (row['name'] ?? row['email'] ?? '').toString().trim();
      if (email.isEmpty) continue;
      users[email] = AssignableUser(
        email: email,
        fullName: (row['full_name'] ?? email).toString(),
      );
    }
    return users.values.toList();
  }
}

class ErpTaskMapper {
  static ErpTask fromJson(Map<String, dynamic> row) => ErpTask(
    name: (row['name'] ?? '').toString(),
    subject: (row['subject'] ?? '').toString(),
    description: (row['description'] ?? '').toString(),
    descriptionText: stripHtmlToPlainText(
      (row['description'] ?? '').toString(),
    ),
    status: (row['status'] ?? 'Open').toString(),
    priority: (row['priority'] ?? 'Medium').toString(),
    progress: double.tryParse('${row['progress'] ?? 0}') ?? 0,
    startDate: (row['exp_start_date'] ?? '').toString(),
    endDate: (row['exp_end_date'] ?? '').toString(),
    company: (row['company'] ?? '').toString(),
    project: (row['project'] ?? '').toString(),
    department: (row['department'] ?? '').toString(),
    owner: (row['owner'] ?? '').toString(),
    modified: (row['modified'] ?? '').toString(),
    isOverdue: _flag(row['is_overdue']),
    canWrite: _flag(row['can_write']),
    assignees: AssignableUserMapper.fromList(row['assignees']),
    previousAssignees: AssignableUserMapper.fromList(row['previous_assignees']),
    allowedStatuses: _strings(row['allowed_statuses']),
  );
}

class TaskListResponseMapper {
  static TaskListResponse fromJson(Map<String, dynamic> json) {
    final root = json['message'] is Map ? _map(json['message']) : json;
    final summary = _map(root['summary']);
    return TaskListResponse(
      user: (root['user'] ?? '').toString(),
      date: (root['date'] ?? '').toString(),
      canCreate: _flag(root['can_create']),
      hasMore: _flag(root['has_more']),
      summary: TaskSummary(
        totalItems: _integer(summary['total_items']),
        openCount: _integer(summary['open_count']),
        workingCount: _integer(summary['working_count']),
        pendingReviewCount: _integer(summary['pending_review_count']),
        completedCount: _integer(summary['completed_count']),
        cancelledCount: _integer(summary['cancelled_count']),
        overdueCount: _integer(summary['overdue_count']),
      ),
      tasks: root['tasks'] is List
          ? (root['tasks'] as List)
                .map((v) => ErpTaskMapper.fromJson(_map(v)))
                .toList()
          : const [],
    );
  }
}

class TaskDetailResponseMapper {
  static TaskDetailResponse fromJson(Map<String, dynamic> json) {
    final root = json['message'] is Map ? _map(json['message']) : json;
    if (root['task'] is! Map) {
      throw const FormatException('Invalid Task response');
    }
    return TaskDetailResponse(task: ErpTaskMapper.fromJson(_map(root['task'])));
  }
}

class TaskOptionsMapper {
  static TaskOptions fromJson(Map<String, dynamic> root) => TaskOptions(
    canCreate: _flag(root['can_create']),
    statuses: _strings(root['statuses']),
    priorities: _strings(root['priorities']),
    companies: _strings(root['companies']),
    users: AssignableUserMapper.fromList(root['users']),
    projects: root['projects'] is List
        ? (root['projects'] as List).map((v) {
            final row = _map(v);
            return TaskProject(
              name: (row['name'] ?? '').toString(),
              title: (row['project_name'] ?? row['name'] ?? '').toString(),
              company: (row['company'] ?? '').toString(),
            );
          }).toList()
        : const [],
  );
}
