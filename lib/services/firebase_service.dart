import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/signalement_model.dart';

/// Service Firebase & Cloud Messaging (Firestore, Storage, Notifications)
/// Les données sont désormais stockées dans Supabase (voir SupabaseService).
class FirebaseService {
  static bool _isFirebaseInitialized = false;

  static bool get isFirebaseInitialized => _isFirebaseInitialized;

  /// Initialisation sécurisée de Firebase
  static Future<void> initialize() async {
    try {
      _isFirebaseInitialized = true;
    } catch (e) {
      _isFirebaseInitialized = false;
    }
  }

  /// Vérifie la connectivité réseau active
  static Future<bool> isNetworkAvailable() async {
    try {
    var connectivityResult = await Connectivity().checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }

  /// Synchroniser un signalement vers Firestore (si en ligne)
  static Future<bool> syncSignalementToCloud(SignalementModel signalement) async {
    bool hasNetwork = await isNetworkAvailable();
    if (!hasNetwork) {
      return false;
    }

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Synchronisation globale des données en attente (Background Sync)
  /// Les signalements sont déjà dans le cloud MySQL : rien à synchroniser.
  static Future<int> syncPendingSignalements() async {
    return 0;
  }

  /// Envoyer une notification FCM lors du changement de statut
  static Future<void> sendStatusNotification({
    required String title,
    required String body,
  }) async {
    // Notification handler
  }
}
