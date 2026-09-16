import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../models/ai_analysis_result.dart';
import '../../models/signalement_model.dart';
import '../../services/ai_service.dart';
import '../../services/location_service.dart';
import '../../services/supabase_service.dart';
import '../../services/validation_service.dart';

void main() {
  runApp(const Signal1());
}

class Signal1 extends StatelessWidget {
  const Signal1({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SignalementPage(),
    );
  }
}

class SignalementPage extends StatefulWidget {
  const SignalementPage({super.key});

  @override
  State<SignalementPage> createState() => _SignalementPageState();
}

class _SignalementPageState extends State<SignalementPage> {
  int etape = 1;

  String typeLieu = "Lieu public";
  String categorie = "Routes";
  String selectedProbleme = "";

  final TextEditingController autreController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController adresseController = TextEditingController();
  final TextEditingController gpsLabelController = TextEditingController();

  List<File> images = [];
  final ImagePicker picker = ImagePicker();

  bool isLoading = false;
  bool isAnalyzingAI = false;

  // Données GPS automatiques
  double? currentLat;
  double? currentLng;

  // Résultat de l'analyse IA
  AIAnalysisResult? aiResult;

  // Timer de debounce pour l'analyse IA
  Timer? _aiDebounceTimer;

  Map<String, Map<String, List<String>>> problemsMap = {
    "Lieu public": {
      "Routes": [
        "Route endommagée / Nid-de-poule",
        "Route inondée",
        "Arbre dangereux",
        "Autre (précisez le problème)",
      ],
      "Éclairage": [
        "Lampadaire en panne",
        "Zone sombre",
        "Autre (précisez le problème)",
      ],
      "Assainissement": [
        "Accumulation de déchets / Poubelle",
        "Égout bouché / Canalisation",
        "Autre (précisez le problème)",
      ],
      "Eau & Fuites": [
        "Fuite d'eau courante",
        "Coupure de conduite",
        "Autre (précisez le problème)",
      ],
    },
    "Bâtiment": {
      "École": [
        "Table cassée",
        "Mur fissuré",
        "Autre (précisez le problème)",
      ],
      "Infrastructure": [
        "Structure physique endommagée",
        "Pont / Dalle défectueuse",
        "Autre (précisez le problème)",
      ],
    },
  };

  @override
  void initState() {
    super.initState();
    _fetchGPSLocation();
  }

  @override
  void dispose() {
    _aiDebounceTimer?.cancel();
    super.dispose();
  }

  /// Obtenir automatiquement les coordonnées GPS actuelles
  Future<void> _fetchGPSLocation() async {
    setState(() => isLoading = true);
    UserLocation loc = await LocationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        currentLat = loc.latitude;
        currentLng = loc.longitude;
        if (loc.address.isNotEmpty) {
          adresseController.text = loc.address;
        }
        gpsLabelController.text =
            "${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}";
        isLoading = false;
      });
    }
  }

  /// Déclenche l'analyse IA avec debounce (évite de surcharger l'UI)
  void _scheduleAIAnalysis() {
    _aiDebounceTimer?.cancel();
    _aiDebounceTimer = Timer(const Duration(milliseconds: 400), () {
      _triggerAIAnalysis();
    });
  }

  /// Exécuter l'analyse IA automatique lors de la saisie ou ajout d'image
  Future<void> _triggerAIAnalysis() async {
    if (descriptionController.text.trim().isEmpty && images.isEmpty) return;
    if (!mounted) return;

    setState(() => isAnalyzingAI = true);

    String? firstImagePath = images.isNotEmpty ? images.first.path : null;

    final result = await AIService.analyzeReport(
      description: descriptionController.text,
      imagePath: firstImagePath,
      currentType: typeLieu,
      currentCategory: categorie,
    );

    if (mounted) {
      setState(() {
        aiResult = result;
        isAnalyzingAI = false;

        // Auto-sélection par l'IA si le problème suggéré existe dans la map
        if (problemsMap.containsKey(result.suggestedType) &&
            problemsMap[result.suggestedType]!.containsKey(result.suggestedCategory)) {
          typeLieu = result.suggestedType;
          categorie = result.suggestedCategory;

          List<String> validProblems = problemsMap[typeLieu]![categorie]!;
          if (validProblems.contains(result.suggestedProblem)) {
            selectedProbleme = result.suggestedProblem;
          } else if (validProblems.isNotEmpty) {
            selectedProbleme = validProblems.first;
          }
        }
      });
    }
  }

  // ------------------- IMAGE PICKER -------------------
  Future<void> pickImage(ImageSource src) async {
    final picked = await picker.pickImage(source: src, imageQuality: 85);
    if (picked != null && mounted) {
      setState(() {
        images.add(File(picked.path));
      });
      _triggerAIAnalysis();
    }
  }

  InputDecoration inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget boutonPrincipal(String txt, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0275D8),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
        child: Text(
          txt,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  /// 🤖 Carte d'affichage des résultats IA
  Widget _buildAICard() {
    if (aiResult == null && !isAnalyzingAI) {
      return Card(
        color: const Color(0xFF0275D8).withValues(alpha: 0.08),
        child: ListTile(
          leading: const Icon(Icons.psychology, color: Color(0xFF0275D8), size: 30),
          title: const Text("Assistante IA SignCi Prête", style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text("Saisissez une description ou une photo pour déclencher l'analyse automatique."),
          trailing: IconButton(
            icon: const Icon(Icons.auto_awesome, color: Color(0xFF0275D8)),
            onPressed: _triggerAIAnalysis,
          ),
        ),
      );
    }

    if (isAnalyzingAI) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 15),
              Expanded(child: Text("L'IA analyse votre signalement...", style: TextStyle(fontWeight: FontWeight.w600))),
            ],
          ),
        ),
      );
    }

    final res = aiResult!;
    Color severityColor = res.severity == "Haute"
        ? Colors.red
        : res.severity == "Moyenne"
            ? Colors.orange
            : Colors.green;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: const Color(0xFF0275D8).withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Color(0xFF0275D8)),
                    SizedBox(width: 8),
                    Text("Analyse Intelligente IA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0275D8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Confiance : ${(res.confidenceScore * 100).toInt()}%",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(),

            // Qualité d'image
            if (res.imageQualityLabel != "Sans image") ...[
              Row(
                children: [
                  Icon(
                    res.imageQualityScore >= 0.6 ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                    size: 18,
                    color: res.imageQualityScore >= 0.6 ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Qualité : ${res.imageQualityLabel} (${(res.imageQualityScore * 100).toInt()}%)",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: res.imageQualityScore >= 0.6 ? Colors.green[800] : Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),
              if (res.imageIssues.any((i) => !i.contains("Aucun défaut")))
                Padding(
                  padding: const EdgeInsets.only(left: 24, top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: res.imageIssues
                        .where((i) => !i.contains("Aucun défaut"))
                        .map((issue) => Text("• $issue", style: TextStyle(fontSize: 11, color: Colors.grey[800])))
                        .toList(),
                  ),
                ),
              const SizedBox(height: 6),
            ],

            // Détection visuelle
            if (res.detectedObjectFromImage != null) ...[
              Row(
                children: [
                  const Icon(Icons.remove_red_eye, color: Color(0xFF701460), size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Visuel : ${res.detectedObjectFromImage}",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF701460), fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],

            // Cohérence image/catégorie
            if (res.coherenceStatus != "Sans image") ...[
              Row(
                children: [
                  Icon(
                    res.coherenceStatus == "Cohérent"
                        ? Icons.verified
                        : res.coherenceStatus == "Incohérent"
                            ? Icons.cancel_outlined
                            : Icons.help_outline,
                    size: 18,
                    color: res.coherenceStatus == "Cohérent"
                        ? Colors.green
                        : res.coherenceStatus == "Incohérent"
                            ? Colors.red
                            : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Cohérence : ${res.coherenceStatus}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: res.coherenceStatus == "Cohérent"
                            ? Colors.green[800]
                            : res.coherenceStatus == "Incohérent"
                                ? Colors.red
                                : Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 2),
                child: Text(
                  res.coherenceMessage,
                  style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                ),
              ),
              const SizedBox(height: 6),
            ],

            Row(
              children: [
                const Text("Priorité IA suggérée : ", style: TextStyle(fontWeight: FontWeight.w500)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    res.severity,
                    style: TextStyle(color: severityColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              res.explanation,
              style: TextStyle(fontSize: 13, color: Colors.grey[800]),
            ),
            if (res.keywords.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: res.keywords
                    .map((k) => Chip(
                          label: Text("#$k", style: const TextStyle(fontSize: 11)),
                          backgroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ------------------- ETAPE 1 -------------------
  Widget etape1() {
    List<String> categories = problemsMap[typeLieu]?.keys.toList() ?? [];
    if (!categories.contains(categorie) && categories.isNotEmpty) {
      categorie = categories[0];
    }
    List<String> problemes = problemsMap[typeLieu]?[categorie] ?? [];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAICard(),
          const SizedBox(height: 15),
          const Text("Type de lieu", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: choix("Lieu public")),
              const SizedBox(width: 10),
              Expanded(child: choix("Bâtiment")),
            ],
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: categories.contains(categorie) ? categorie : null,
            items: categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() {
              categorie = v!;
              selectedProbleme = "";
            }),
            decoration: inputStyle("Catégorie"),
          ),
          const SizedBox(height: 20),
          const Text("Choisir un problème", style: TextStyle(fontWeight: FontWeight.bold)),
          RadioGroup<String>(
            groupValue: selectedProbleme,
            onChanged: (v) {
              if (v != null) setState(() => selectedProbleme = v);
            },
            child: Column(
              children: problemes.map((p) {
                return RadioListTile<String>(
                  title: Text(p),
                  value: p,
                );
              }).toList(),
            ),
          ),
          if (selectedProbleme.contains("Autre (précisez le problème)") &&
              selectedProbleme.trim().length <= "Autre".length + 20)
            TextField(
              controller: autreController,
              decoration: inputStyle("Précisez le problème"),
            ),
          const SizedBox(height: 20),
          boutonPrincipal("Suivant", () => setState(() => etape = 2)),
        ],
      ),
    );
  }

  // ------------------- ETAPE 2 -------------------
  Widget etape2() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- PHOTOS ---
          const Text("Photos du problème", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: photoBtn("Caméra", ImageSource.camera)),
              const SizedBox(width: 10),
              Expanded(child: photoBtn("Galerie", ImageSource.gallery)),
            ],
          ),
          const SizedBox(height: 10),
          if (images.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: images.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            e,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                images.remove(e);
                                _triggerAIAnalysis();
                              });
                            },
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.red,
                              child: Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 20),

          // --- DESCRIPTION ---
          TextField(
            controller: descriptionController,
            maxLines: 3,
            maxLength: 2000,
            onChanged: (_) => _scheduleAIAnalysis(),
            decoration: inputStyle("Description détaillée du problème (min 15 caractères)..."),
          ),
          const SizedBox(height: 20),

          // --- LOCALISATION GPS AUTOMATIQUE ---
          const Text("Localisation", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.my_location, color: Color(0xFF0275D8), size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          "Position GPS (automatique)",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0275D8), fontSize: 14),
                        ),
                      ),
                      if (isLoading)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 20),
                          onPressed: _fetchGPSLocation,
                          tooltip: "Rafraîchir la position GPS",
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    gpsLabelController.text.isNotEmpty
                        ? gpsLabelController.text
                        : "Chargement...",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    adresseController.text.isNotEmpty
                        ? adresseController.text
                        : "Adresse en cours de localisation...",
                    style: const TextStyle(fontSize: 13),
                    maxLines: 2,
                  ),

                  // Mini carte de prévisualisation
                  if (currentLat != null && currentLng != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        height: 130,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(currentLat!, currentLng!),
                            initialZoom: 15,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.none,
                            ),
                            cameraConstraint: CameraConstraint.contain(
                              bounds: LatLngBounds(
                                const LatLng(LocationService.minLat, LocationService.minLng),
                                const LatLng(LocationService.maxLat, LocationService.maxLng),
                              ),
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
                              subdomains: const ['a', 'b', 'c'],
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(currentLat!, currentLng!),
                                  width: 30,
                                  height: 30,
                                  child: const Icon(Icons.location_on, color: Colors.red, size: 30),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),

          // --- BOUTONS ---
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () => setState(() => etape = 1),
                  child: const Text("Retour"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: boutonPrincipal("Aperçu & IA", preview),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Validation avant prévisualisation + détection de doublons
  Future<void> preview() async {
    final probText = selectedProbleme.contains("Autre (précisez le problème)")
        ? autreController.text.trim()
        : selectedProbleme;

    final validation = ValidationService.validateSignalement(
      probleme: probText,
      description: descriptionController.text,
      adresse: adresseController.text,
      latitude: currentLat,
      longitude: currentLng,
      images: images,
      aiResult: aiResult,
    );

    if (!validation.isValid && mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Expanded(child: Text("Signalement incomplet", style: TextStyle(fontSize: 18))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...validation.errors.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text("• $e", style: const TextStyle(fontSize: 13)),
                  )),
              if (validation.warnings.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text("Avertissements :", style: TextStyle(fontSize: 12, color: Colors.orange[800], fontWeight: FontWeight.bold)),
                ...validation.warnings.map((w) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text("⚠ $w", style: TextStyle(fontSize: 12, color: Colors.orange[800])),
                    )),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Corriger"),
            ),
          ],
        ),
      );
      return;
    }

    // Si avertissements IA mais pas d'erreur bloquante, proposer quand même
    if (validation.warnings.isNotEmpty && validation.errors.isEmpty && mounted) {
      bool proceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.help_outline, color: Colors.orange, size: 28),
                  SizedBox(width: 8),
                  Expanded(child: Text("Vérification IA", style: TextStyle(fontSize: 18))),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: validation.warnings.map((w) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text("⚠ $w", style: const TextStyle(fontSize: 13)),
                    )).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text("Modifier"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text("Continuer"),
                ),
              ],
            ),
          ) ??
          false;

      if (!proceed) return;
    }

    final existingReports = await SupabaseService.getAllSignalements();
    final duplicates = AIService.findDuplicates(
      category: categorie,
      description: descriptionController.text,
      lat: currentLat,
      lng: currentLng,
      existingReports: existingReports,
    );

    if (duplicates.isNotEmpty && mounted) {
      final match = duplicates.first;
      _showDuplicateDialog(match, probText);
    } else if (mounted) {
      _navigateToPreviewPage(probText);
    }
  }

  /// Dialog d'alerte de doublon permettant la confirmation citoyenne (+1 Vote)
  void _showDuplicateDialog(DuplicateMatch match, String probText) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Expanded(child: Text("Signalement similaire !", style: TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Un problème similaire a déjà été signalé à ${(match.distanceMeters.isFinite ? match.distanceMeters.toInt() : 0)} mètres :",
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("🚨 ${match.existingReport.probleme}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(match.existingReport.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text("👍 ${match.existingReport.upvotesCount} confirmation(s) citoyenne(s)", style: const TextStyle(fontSize: 12, color: Color(0xFF0275D8), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "Pour éviter les doublons et augmenter l'urgence auprès des services municipaux, vous pouvez appuyer sur 'Confirmer ce problème'.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _navigateToPreviewPage(probText);
            },
            child: const Text("Créer quand même"),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              if (match.existingReport.id != null) {
                await SupabaseService.upvote(match.existingReport.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Merci ! Vous avez confirmé ce problème (+1 Vote)")),
                  );
                }
              }
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.thumb_up, color: Colors.white, size: 18),
            label: const Text("Confirmer l'existant", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _navigateToPreviewPage(String probText) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreviewPage(
          type: typeLieu,
          categorie: categorie,
          probleme: probText,
          description: descriptionController.text,
          adresse: adresseController.text,
          images: images,
          latitude: currentLat,
          longitude: currentLng,
          aiResult: aiResult,
          onSubmit: submit,
        ),
      ),
    );
  }

  Widget choix(String txt) {
    bool selected = typeLieu == txt;

    return GestureDetector(
      onTap: () {
        setState(() {
          typeLieu = txt;
          categorie = problemsMap[typeLieu]?.keys.first ?? "";
          selectedProbleme = "";
        });
        _triggerAIAnalysis();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0275D8).withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? const Color(0xFF0275D8) : Colors.grey[300]!),
        ),
        child: Center(
          child: Text(
            txt,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selected ? const Color(0xFF0275D8) : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget photoBtn(String txt, ImageSource src) {
    return GestureDetector(
      onTap: () => pickImage(src),
      child: Container(
        height: 55,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: Text(txt, style: const TextStyle(fontWeight: FontWeight.bold))),
      ),
    );
  }

  Future<void> submit() async {
    setState(() => isLoading = true);

    // Envoi des photos vers Supabase Storage pour obtenir des URLs publiques
    // (indispensable pour afficher les photos sur le web / l'admin).
    List<String> uploadedUrls = [];
    int failed = 0;
    for (final img in images) {
      final url = await SupabaseService.uploadImageToStorage(img.path);
      if (url != null) {
        uploadedUrls.add(url);
      } else {
        failed++;
      }
    }
    String imagePaths = uploadedUrls.join(";");

    final probText = selectedProbleme.contains("Autre (précisez le problème)")
        ? autreController.text.trim()
        : selectedProbleme;

    final model = SignalementModel(
      type: typeLieu,
      categorie: categorie,
      probleme: probText,
      description: descriptionController.text,
      adresse: adresseController.text,
      image: imagePaths,
      status: "En attente",
      latitude: currentLat,
      longitude: currentLng,
      priorite: aiResult?.severity ?? "Moyenne",
      confidenceScore: aiResult?.confidenceScore ?? 0.80,
      keywords: aiResult?.keywords ?? [],
      upvotesCount: 1,
      isDuplicate: false,
      isCriticalZone: false,
    );

    await SupabaseService.insertSignalement(model);

    if (mounted) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          failed == 0
              ? "Signalement envoyé avec succès ✅"
              : "Signalement envoyé, mais $failed photo(s) non uploadée(s) ⚠️",
        ),
      ));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Créer un Signalement IA")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: etape == 1 ? etape1() : etape2(),
      ),
    );
  }
}

class PreviewPage extends StatelessWidget {
  final String type;
  final String categorie;
  final String probleme;
  final String description;
  final String adresse;
  final List<File> images;
  final double? latitude;
  final double? longitude;
  final AIAnalysisResult? aiResult;
  final VoidCallback onSubmit;

  const PreviewPage({
    super.key,
    required this.type,
    required this.categorie,
    required this.probleme,
    required this.description,
    required this.adresse,
    required this.images,
    this.latitude,
    this.longitude,
    this.aiResult,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Aperçu du Signalement")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (aiResult != null) ...[
              Card(
                color: const Color(0xFF0275D8).withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Diagnostic IA", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("Score: ${(aiResult!.confidenceScore * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0275D8))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text("Priorité : ${aiResult!.severity}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(aiResult!.explanation, style: const TextStyle(fontSize: 13)),
                      if (aiResult!.coherenceStatus != "Sans image") ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              aiResult!.coherenceStatus == "Cohérent" ? Icons.verified : Icons.help_outline,
                              size: 16,
                              color: aiResult!.coherenceStatus == "Cohérent" ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "Cohérence : ${aiResult!.coherenceMessage}",
                                style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Type : $type • $categorie", style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 5),
                    Text("Problème : $probleme", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text("Description : $description"),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.red, size: 18),
                        const SizedBox(width: 4),
                        Expanded(child: Text("Adresse : $adresse")),
                      ],
                    ),
                    if (latitude != null && longitude != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        "GPS : ${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (images.isNotEmpty) ...[
              const Text("Photos jointes :", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: images
                      .map((img) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(img, width: 120, height: 120, fit: BoxFit.cover),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0275D8),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onSubmit,
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text("Valider & Envoyer à SignCi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}