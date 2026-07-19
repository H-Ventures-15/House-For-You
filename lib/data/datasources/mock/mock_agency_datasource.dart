import '../../models/agency.dart';
import '../../repositories/agency_repository.dart';
import 'mock_agency_data.dart';

class MockAgencyDataSource implements AgencyRepository {
  static const _simulatedDelay = Duration(milliseconds: 200);

  @override
  Future<List<Agency>> getAll() async {
    await Future<void>.delayed(_simulatedDelay);
    return List.unmodifiable(mockAgencies);
  }

  @override
  Future<Agency?> getById(String id) async {
    await Future<void>.delayed(_simulatedDelay);
    try {
      return mockAgencies.firstWhere((a) => a.id == id);
    } on StateError {
      return null;
    }
  }
}
