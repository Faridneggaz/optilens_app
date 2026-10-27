import '../../domain/entities/activity_report.dart';

class ActivityReportMapper {
  static String text(dynamic v) => v?.toString() ?? '';
  static bool flag(dynamic v) => v == true || v == 1 || v == '1';
  static List<Map<String, dynamic>> rows(dynamic v) => v is List
      ? v.whereType<Map>().map((r) => Map<String, dynamic>.from(r)).toList()
      : [];
  static ActivityReport report(Map<String, dynamic> m) => ActivityReport(
    name: text(m['name']),
    title: text(m['title']),
    type: text(m['doc_type']),
    date: text(m['date']),
    process: text(m['process_link']),
    owner: text(m['owner']),
    modified: text(m['modified']),
    actionCount:
        int.tryParse(text(m['action_count'])) ?? rows(m['task_list']).length,
    done: rows(m['done_list'])
        .map(
          (r) => ReportLine(
            name: text(r['name']),
            description: text(r['description']),
          ),
        )
        .toList(),
    issues: rows(m['issue_list'])
        .map(
          (r) => ReportLine(
            name: text(r['name']),
            description: text(r['description']),
          ),
        )
        .toList(),
    participants: rows(m['attendance_list'])
        .map(
          (r) => ReportParticipant(
            name: text(r['name']),
            employee: text(r['employee']),
            employeeName: text(r['employee_name']).isEmpty
                ? text(r['employee'])
                : text(r['employee_name']),
            present: flag(r['present']),
          ),
        )
        .toList(),
    actions: rows(m['task_list'])
        .map(
          (r) => ReportAction(
            name: text(r['name']),
            description: text(r['description']),
            taskLink: text(r['task_link']),
            taskSubject: text(r['task_subject']),
            canReadTask: flag(r['can_read_task']),
            responsibleEmployee: text(r['responsible_employee']),
            responsibleName: text(r['responsible_name']),
            deadline: text(r['deadline']),
            status: text(r['status']).isEmpty ? 'Open' : text(r['status']),
          ),
        )
        .toList(),
  );
  static ActivityReportList list(Map<String, dynamic> m) => ActivityReportList(
    reports: rows(m['reports']).map(report).toList(),
    total: int.tryParse(text(m['total_items'])) ?? 0,
    hasMore: flag(m['has_more']),
    canCreate: flag(m['can_create']),
  );
  static ActivityReportResult result(Map<String, dynamic> m) =>
      ActivityReportResult(
        report: m['report'] is Map
            ? report(Map<String, dynamic>.from(m['report']))
            : null,
        canRead: flag(m['can_read']),
        canWrite: flag(m['can_write']),
      );
  static ActivityReportOptions options(Map<String, dynamic> m) =>
      ActivityReportOptions(
        types: (m['report_types'] as List? ?? []).map(text).toList(),
        statuses: (m['action_statuses'] as List? ?? []).map(text).toList(),
        canCreate: flag(m['can_create']),
        currentEmployee: m['current_employee'] is Map
            ? ReportOption(
                value: text(m['current_employee']['name']),
                label: text(m['current_employee']['employee_name']),
              )
            : null,
        items: rows(m['items'])
            .map(
              (r) => ReportOption(
                value: text(r['value']),
                label: text(r['label']).replaceAll(RegExp(r'<[^>]+>'), ' '),
              ),
            )
            .toList(),
      );
  static Map<String, dynamic> input(ActivityReport r) => {
    'title': r.title.trim(),
    'doc_type': r.type,
    'date': r.date,
    'process_link': r.process,
    'done_list': r.done
        .map(
          (l) => {
            if (l.name.isNotEmpty) 'name': l.name,
            'description': l.description.trim(),
          },
        )
        .toList(),
    'issue_list': r.issues
        .map(
          (l) => {
            if (l.name.isNotEmpty) 'name': l.name,
            'description': l.description.trim(),
          },
        )
        .toList(),
    'attendance_list': r.participants
        .map(
          (p) => {
            if (p.name.isNotEmpty) 'name': p.name,
            'employee': p.employee,
            'present': p.present ? 1 : 0,
          },
        )
        .toList(),
    'task_list': r.actions
        .map(
          (a) => {
            if (a.name.isNotEmpty) 'name': a.name,
            'description': a.description.trim(),
            'task_link': a.taskLink,
            'responsible_employee': a.responsibleEmployee,
            'deadline': a.deadline,
            'status': a.status,
          },
        )
        .toList(),
  };
}
