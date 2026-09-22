import '../../core/network/api_client.dart';
import '../../domain/entities/job_profile.dart';
import '../../domain/failures/failures.dart';
import '../../domain/repositories/job_profile_repository.dart';
import '../mappers/json_mappers.dart';

class JobProfileRepositoryImpl implements JobProfileRepository {
  JobProfileRepositoryImpl(this._client);

  final ApiClient _client;

  @override
  Future<MyJobProfileResponse> fetchMyJobProfile({
    required String token,
  }) async {
    final decoded = await _client.getMobile(
      'get_my_job_profile',
      query: {'token': token},
      attachToken: false,
    );
    final msg = _client.unwrap(decoded);
    if (msg is Map) {
      final map = Map<String, dynamic>.from(msg);
      final err = map['error']?.toString();
      if (err != null && err.isNotEmpty && err != 'null') {
        throw RepositoryException(err);
      }
      return MyJobProfileResponseMapper.fromJson(map);
    }
    if (decoded['error'] != null &&
        '${decoded['error']}'.isNotEmpty &&
        '${decoded['error']}' != 'null') {
      throw RepositoryException('${decoded['error']}');
    }
    if (decoded.containsKey('employee') || decoded.containsKey('job_profile')) {
      return MyJobProfileResponseMapper.fromJson(decoded);
    }
    throw const RepositoryException('Invalid job profile response');
  }
}
