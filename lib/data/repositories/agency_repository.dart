import '../models/agency.dart';

abstract class AgencyRepository {
  Future<List<Agency>> getAll();

  Future<Agency?> getById(String id);
}
