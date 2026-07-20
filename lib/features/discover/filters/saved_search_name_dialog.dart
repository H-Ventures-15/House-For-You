import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';

/// Dialogue partagé pour nommer une recherche sauvegardée — utilisé à
/// l'enregistrement (`filters_sheet.dart`, nom par défaut pré-rempli) et au
/// renommage (`saved_searches_sheet.dart`, nom actuel pré-rempli). Retourne
/// `null` si annulé, sinon le texte saisi (potentiellement vide — l'appelant
/// décide du repli sur un nom par défaut, voir `defaultSavedSearchName`).
Future<String?> promptSavedSearchName({
  required BuildContext context,
  required String title,
  required String initialValue,
  String confirmLabel = 'Enregistrer',
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _SavedSearchNameDialog(
      title: title,
      initialValue: initialValue,
      confirmLabel: confirmLabel,
    ),
  );
}

/// Porte son propre `TextEditingController`, créé/détruit avec le cycle de
/// vie du `State` plutôt qu'un contrôleur externe disposé "à la main" dès
/// que le `Future` de `showDialog` se résout : la transition de fermeture
/// du dialogue continue de peindre quelques frames après ce moment-là, et
/// un contrôleur disposé trop tôt y provoque une erreur ("used after being
/// disposed"). Laisser Flutter appeler `dispose()` au démontage réel de
/// l'`Element` évite complètement cette course.
class _SavedSearchNameDialog extends StatefulWidget {
  const _SavedSearchNameDialog({
    required this.title,
    required this.initialValue,
    required this.confirmLabel,
  });

  final String title;
  final String initialValue;
  final String confirmLabel;

  @override
  State<_SavedSearchNameDialog> createState() => _SavedSearchNameDialogState();
}

class _SavedSearchNameDialogState extends State<_SavedSearchNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title, style: AppTypography.titleMedium),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'Nom de la recherche'),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
