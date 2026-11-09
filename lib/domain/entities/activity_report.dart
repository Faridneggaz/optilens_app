class ReportOption {
  const ReportOption({required this.value, required this.label});
  final String value;
  final String label;
}

class ReportLine {
  const ReportLine({this.name = '', required this.description});
  final String name;
  final String description;
}

class ReportParticipant {
  const ReportParticipant({
    this.name = '',
    required this.employee,
    required this.employeeName,
    this.present = true,
  });
  final String name;
  final String employee;
  final String employeeName;
  final bool present;
  ReportParticipant withPresence(bool value) => ReportParticipant(
    name: name,
    employee: employee,
    employeeName: employeeName,
    present: value,
  );
}

class ReportAction {
  const ReportAction({
    this.name = '',
    required this.description,
    this.taskLink = '',
    this.taskSubject = '',
    this.canReadTask = false,
    this.responsibleEmployee = '',
    this.responsibleName = '',
    this.deadline = '',
    this.status = 'Open',
  });
  final String name;
  final String description;
  final String taskLink;
  final String taskSubject;
  final bool canReadTask;
  final String responsibleEmployee;
  final String responsibleName;
  final String deadline;
  final String status;
}

class ActivityReport {
  const ActivityReport({
    this.name = '',
    this.title = '',
    this.type = 'Weekly Report',
    this.date = '',
    this.process = '',
    this.owner = '',
    this.modified = '',
    this.actionCount = 0,
    this.done = const [],
    this.issues = const [],
    this.actions = const [],
    this.participants = const [],
  });
  final String name;
  final String title;
  final String type;
  final String date;
  final String process;
  final String owner;
  final String modified;
  final int actionCount;
  final List<ReportLine> done;
  final List<ReportLine> issues;
  final List<ReportAction> actions;
  final List<ReportParticipant> participants;
  bool get isWeekly => type == 'Weekly Report';
  ActivityReport copyWith({
    String? title,
    String? type,
    String? date,
    String? process,
    List<ReportLine>? done,
    List<ReportLine>? issues,
    List<ReportAction>? actions,
    List<ReportParticipant>? participants,
  }) => ActivityReport(
    name: name,
    title: title ?? this.title,
    type: type ?? this.type,
    date: date ?? this.date,
    process: process ?? this.process,
    owner: owner,
    modified: modified,
    actionCount: actionCount,
    done: done ?? this.done,
    issues: issues ?? this.issues,
    actions: actions ?? this.actions,
    participants: participants ?? this.participants,
  );
}

class ActivityReportList {
  const ActivityReportList({
    this.reports = const [],
    this.total = 0,
    this.hasMore = false,
    this.canCreate = false,
  });
  final List<ActivityReport> reports;
  final int total;
  final bool hasMore;
  final bool canCreate;
}

class ActivityReportResult {
  const ActivityReportResult({
    this.report,
    this.canRead = false,
    this.canWrite = false,
  });
  final ActivityReport? report;
  final bool canRead;
  final bool canWrite;
}

class ActivityReportOptions {
  const ActivityReportOptions({
    this.types = const [],
    this.statuses = const [],
    this.currentEmployee,
    this.items = const [],
    this.canCreate = false,
  });
  final List<String> types;
  final List<String> statuses;
  final ReportOption? currentEmployee;
  final List<ReportOption> items;
  final bool canCreate;
}
