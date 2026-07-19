import '../models/lead.dart';

/// Enregistre les demandes de contact/visite (table `leads`, voir
/// architecture-mvp.md section 5) — nécessite une session utilisateur.
abstract class LeadsRepository {
  Future<Lead> createLead(Lead lead);
}
