import 'dart:typed_data';

import 'attachment_photo.dart';

typedef TaskVoiceAudio = ({Uint8List bytes, String mimeType});

class TaskSummary {
  const TaskSummary({
    this.totalItems = 0,
    this.openCount = 0,
    this.workingCount = 0,
    this.pendingReviewCount = 0,
    this.completedCount = 0,
    this.cancelledCount = 0,
    this.overdueCount = 0,
  });
  final int totalItems;
  final int openCount;
  final int workingCount;
  final int pendingReviewCount;
  final int completedCount;
  final int cancelledCount;
  final int overdueCount;
}

class AssignableUser {
  const AssignableUser({required this.email, required this.fullName});
  final String email;
  final String fullName;
  String get displayName => fullName.trim().isEmpty ? email : fullName;
  String get subtitle => email;
}

class ErpTask {
  const ErpTask({
    required this.name,
    required this.subject,
    this.description = '',
    this.descriptionText = '',
    this.status = 'Open',
    this.priority = 'Medium',
    this.progress = 0,
    this.startDate = '',
    this.endDate = '',
    this.company = '',
    this.project = '',
    this.type = '',
    this.department = '',
    this.owner = '',
    this.modified = '',
    this.isOverdue = false,
    this.canWrite = false,
    this.assignees = const [],
    this.previousAssignees = const [],
    this.allowedStatuses = const [],
    this.photos = const [],
    this.voiceIds = const [],
    this.attachmentCount,
  });
  final String name;
  final String subject;
  final String description;
  final String descriptionText;
  final String status;
  final String priority;
  final double progress;
  final String startDate;
  final String endDate;
  final String company;
  final String project;
  final String type;
  final String department;
  final String owner;
  final String modified;
  final bool isOverdue;
  final bool canWrite;
  final List<AssignableUser> assignees;
  final List<AssignableUser> previousAssignees;
  final List<String> allowedStatuses;
  final List<AttachmentPhoto> photos;
  final List<String> voiceIds;
  final int? attachmentCount;
  bool get isFinished => status == 'Completed' || status == 'Cancelled';
}

/// Omitted description, project and type are preserved when editing.
class TaskInput {
  const TaskInput({
    required this.subject,
    this.description,
    this.company = '',
    this.project,
    this.startDate = '',
    this.endDate = '',
    this.priority = 'Medium',
    this.progress = 0,
    this.assignees = const [],
    this.updateAssignments = true,
    this.photos = const [],
    this.voiceRecordings = const [],
    this.removedVoiceIds = const [],
    this.issue = '',
    this.type,
  });
  final String subject;
  final String? description;
  final String company;
  final String? project;
  final String startDate;
  final String endDate;
  final String priority;
  final double progress;
  final List<String> assignees;
  final bool updateAssignments;
  final List<SelectedPhoto> photos;
  final List<Uint8List> voiceRecordings;
  final List<String> removedVoiceIds;
  final String issue;
  final String? type;
}

class TaskProject {
  const TaskProject({
    required this.name,
    required this.title,
    this.company = '',
  });
  final String name;
  final String title;
  final String company;
}

class TaskOptions {
  const TaskOptions({
    this.canCreate = false,
    this.photoMaxBytes = 0,
    this.photoBatchMaxBytes = 0,
    this.photoMaxCount = 1,
    this.attachmentLimit = 5,
    this.voiceMaxBytes = 0,
    this.canRemoveVoice = false,
    this.statuses = const [],
    this.priorities = const [],
    this.types = const [],
    this.companies = const [],
    this.users = const [],
    this.projects = const [],
  });
  final bool canCreate;
  final int photoMaxBytes;
  final int photoBatchMaxBytes;
  final int photoMaxCount;
  final int attachmentLimit;
  final int voiceMaxBytes;
  final bool canRemoveVoice;
  final List<String> statuses;
  final List<String> priorities;
  final List<String> types;
  final List<String> companies;
  final List<AssignableUser> users;
  final List<TaskProject> projects;
}

class TaskListResponse {
  const TaskListResponse({
    required this.user,
    required this.date,
    required this.summary,
    required this.tasks,
    this.canCreate = false,
    this.hasMore = false,
  });
  final String user;
  final String date;
  final TaskSummary summary;
  final List<ErpTask> tasks;
  final bool canCreate;
  final bool hasMore;
}

class TaskDetailResponse {
  const TaskDetailResponse({required this.task});
  final ErpTask task;
  bool get canWrite => task.canWrite;
}
