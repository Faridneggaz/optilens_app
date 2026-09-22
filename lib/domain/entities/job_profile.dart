class JobArticle {
  const JobArticle({
    required this.idx,
    required this.description,
  });

  final int idx;
  final String description;
}

class EmployeeHeader {
  const EmployeeHeader({
    required this.name,
    required this.employeeName,
    required this.userId,
    required this.designation,
    required this.department,
    required this.company,
    required this.status,
  });

  final String name;
  final String employeeName;
  final String userId;
  final String designation;
  final String department;
  final String company;
  final String status;
}

class JobProfile {
  const JobProfile({
    required this.name,
    required this.jobTitle,
    required this.hierarchicalReporting,
    required this.hierarchicalRelation,
    required this.functionalReporting,
    required this.generalMissionText,
    required this.authorities,
    required this.tasks,
    required this.workflowState,
    required this.docstatus,
  });

  final String name;
  final String jobTitle;
  final String hierarchicalReporting;
  final String hierarchicalRelation;
  final String functionalReporting;
  final String generalMissionText;
  final List<JobArticle> authorities;
  final List<JobArticle> tasks;
  final String workflowState;
  final int docstatus;

  String get displayTitle =>
      jobTitle.trim().isNotEmpty ? jobTitle.trim() : '';
}

class MyJobProfileResponse {
  const MyJobProfileResponse({
    required this.success,
    this.error,
    this.message,
    this.employee,
    this.jobProfile,
  });

  final bool success;
  final String? error;
  final String? message;
  final EmployeeHeader? employee;
  final JobProfile? jobProfile;

  bool get hasProfile => jobProfile != null;
}
