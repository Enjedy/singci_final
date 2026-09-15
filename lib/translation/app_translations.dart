/// Gestion centralisée des traductions de l'application SignCi.
///
/// Plutôt que d'avoir une Map globale éparpillée dans main.dart,
/// toutes les chaînes traduites passent par cette classe. Cela permet :
/// - d'ajouter facilement une nouvelle langue (il suffit d'ajouter une entrée)
/// - d'avoir un fallback automatique vers le français si une clé manque
/// - de garder main.dart concentré sur l'UI, pas sur le contenu textuel
class AppTranslations {
  AppTranslations._();

  static const String defaultLanguage = 'fr';

  static const Map<String, Map<String, String>> _values = {
    'fr': {
      'title': 'SignCi',
      'welcome': 'Bonjour',
      'subtitle': 'Votre ville, entre vos mains',
      'bouton': 'Commencer',
      'login_button': 'J\'ai déjà un compte',
      'desc_title': 'Que fait cette application ?',
      'desc':
          'SignCI vous permet de signaler rapidement les problèmes rencontrés '
          'dans votre ville ou sur la route.\n\n'
          'Grâce à son intelligence artificielle intégrée, l\'application '
          'analyse vos photos et descriptions pour catégoriser, prioriser et '
          'éviter les doublons automatiquement.',
      'feature_report': 'Signalez en quelques secondes',
      'feature_track': 'Suivez le traitement en temps réel',
      'feature_ai': 'Priorisation assistée par IA',
    },
    'mg': {
      'title': 'SignCi',
      'welcome': 'Tongasoa',
      'subtitle': 'Ny tanànanao, eo an-tananao',
      'bouton': 'Manomboka',
      'login_button': 'Efa manana kaonty aho',
      'desc_title': 'Inona no ataon\'ity app ity?',
      'desc':
          'Ny SignCI dia mamela anao hanao tatitra haingana momba ny olana '
          'hita eny amin\'ny tanàna misy anao na eny an-dalana.\n\n'
          'Miaraka amin\'ny Intelligence Artificielle voafantina ao anatiny, '
          'ny app dia mamakafaka ny sary sy ny famaritana mba hanokanana '
          'sokajy, laharam-pahamehana, ary hisorohana ny fitovian\'ny tatitra.',
      'feature_report': 'Manao tatitra amin\'ny segondra vitsivitsy',
      'feature_track': 'Araho ny fandehan\'ny raharaha amin\'ny fotoana rahateo',
      'feature_ai': 'Fanaovana laharam-pahamehana ampian\'ny IA',
    },
  };

  /// Renvoie la traduction pour [key] dans la langue [lang].
  /// Si la clé n'existe pas dans [lang], retombe sur le français,
  /// puis sur la clé elle-même en dernier recours (jamais d'écran vide).
  static String t(String key, String lang) {
    return _values[lang]?[key] ??
        _values[defaultLanguage]?[key] ??
        key;
  }

  static List<String> get supportedLanguages => _values.keys.toList();
}

// --- Compatibilité avec l'ancien code (main.dart historique) ---
// Si d'autres fichiers utilisent encore `tr(key, lang)` ou `translations[...]`
// importés depuis main.dart, ces alias évitent de tout casser d'un coup.
String tr(String key, String lang) => AppTranslations.t(key, lang);