import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Charge .env si présent (jamais commité, voir .env.example). En mode mock
  // (DATA_SOURCE_MODE=mock, valeur par défaut), aucune clé n'est requise —
  // l'absence de .env ne doit donc jamais bloquer le lancement de l'app.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    if (kDebugMode) {
      debugPrint(
        'Aucun .env trouvé — OK en mode mock, copier .env.example sinon.',
      );
    }
  }

  runApp(const HouseForYouApp());
}
