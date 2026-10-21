import '../entities/job_profile.dart';
import '../repositories/job_profile_repository.dart';

class JobProfileUseCases {
  JobProfileUseCases(this._repo);
  final JobProfileRepository _repo;

  Future<MyJobProfileResponse> fetchMyJobProfile({required String token}) =>
      _repo.fetchMyJobProfile(token: token);
}
