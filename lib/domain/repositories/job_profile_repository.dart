import '../entities/job_profile.dart';

abstract class JobProfileRepository {
  Future<MyJobProfileResponse> fetchMyJobProfile({required String token});
}
