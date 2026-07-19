import 'package:flutter/foundation.dart';
import '../../models/lead.dart';
import '../../repositories/leads_repository.dart';

/// Stockage en mémoire — remplacé par la table Supabase `leads` (via une
/// écriture directe autorisée par RLS aux utilisateurs connectés) à l'étape
/// 10 du plan.
class MockLeadsDataSource implements LeadsRepository {
  final List<Lead> _leads = [];

  @override
  Future<Lead> createLead(Lead lead) async {
    _leads.add(lead);
    if (kDebugMode) {
      debugPrint(
        '[MockLeadsDataSource] nouveau lead ${lead.type.name} pour ${lead.propertyId}',
      );
    }
    return lead;
  }
}
