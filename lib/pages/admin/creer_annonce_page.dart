import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/annonce_model.dart';
import '../../services/supabase_service.dart';

/// Page administrateur : publier une nouvelle annonce à destination des citoyens.
/// L'image peut venir de la caméra, de la galerie ou de la bibliothèque SignCi.
class CreerAnnoncePage extends StatefulWidget {
  const CreerAnnoncePage({super.key});

  /// Images SignCi prêtes à l'emploi (dossier assets/annonce).
  static const List<String> libImages = [
    'assets/annonce/797644950_2182881668924647_3353259951416021745_n.jpg',
    'assets/annonce/796526581_2250814579036092_2876472882599594840_n.jpg',
    'assets/annonce/796080986_28359099907020129_5002968598003006007_n.jpg',
    'assets/annonce/794992024_1719856369128411_5289480390484959317_n.jpg',
    'assets/annonce/791228259_1623371599271738_5301682362163153885_n.jpg',
    'assets/annonce/790412120_1821100305896671_6262998083476413542_n.jpg',
    'assets/annonce/789342499_1643821373982655_274874893800238391_n.jpg',
    'assets/annonce/789217724_1849197882727307_8014610624539263062_n.jpg',
    'assets/annonce/786927634_1397219472344496_8743830072071612962_n.jpg',
    'assets/annonce/783856915_1391267812961735_3401710838184237118_n.jpg',
    'assets/annonce/783507434_1101232109129074_2980684274175643221_n.jpg',
  ];

  @override
  State<CreerAnnoncePage> createState() => _CreerAnnoncePageState();
}

class _CreerAnnoncePageState extends State<CreerAnnoncePage> {
  final TextEditingController titreController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String? _imagePath;
  bool isPublishing = false;
  final ImagePicker picker = ImagePicker();

  @override
  void dispose() {
    titreController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFrom(ImageSource source) async {
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null && mounted) {
      setState(() => _imagePath = picked.path);
    }
  }

  Future<void> _publish() async {
    final titre = titreController.text.trim();
    final description = descriptionController.text.trim();

    if (titre.isEmpty) {
      _showError("Le titre est obligatoire.");
      return;
    }
    if (description.length < 20) {
      _showError("La description doit contenir au moins 20 caractères.");
      return;
    }

    setState(() => isPublishing = true);

    // Si la photo vient de la galerie/caméra (chemin local), on l'upload
    // vers Supabase Storage pour obtenir une URL publique affichable partout.
    String imageValue = _imagePath ?? '';
    if (imageValue.isNotEmpty &&
        !imageValue.startsWith('assets/') &&
        !imageValue.startsWith('http')) {
      final url = await SupabaseService.uploadImageToStorage(imageValue);
      imageValue = url ?? '';
    }

    final annonce = AnnonceModel(
      titre: titre,
      description: description,
      image: imageValue,
      auteur: "Administration SignCi",
    );

    try {
      await SupabaseService.insertAnnonce(annonce);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Annonce publiée avec succès 🎉")),
        );
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => isPublishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "Échec de la publication. Vérifiez la connexion.")),
        );
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Publier une Annonce"),
        backgroundColor: const Color(0xFF0275D8),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Aperçu style Facebook ----
            if (_imagePath != null || true) ...[
              Center(
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 320),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0275D8).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFF0275D8).withValues(alpha: 0.3)),
                  ),
                  child: _imagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            File(_imagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Icon(
                                Icons.image_not_supported_outlined),
                          ),
                        )
                      : const Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  size: 44, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                "Aucune image sélectionnée",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ],

            _sectionTitle("Titre de l'annonce"),
            TextField(
              controller: titreController,
              maxLength: 120,
              decoration: InputDecoration(
                hintText: "Ex : Campagne de nettoyage de la ville",
                filled: true,
                fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            _sectionTitle("Description (minimum 20 caractères)"),
            TextField(
              controller: descriptionController,
              maxLines: 5,
              maxLength: 2000,
              decoration: InputDecoration(
                hintText: "Décrivez l'actualité pour les citoyens...",
                filled: true,
                fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            _sectionTitle("Ajouter une photo"),
            Row(
              children: [
                Expanded(
                  child: _photoButton(
                    icon: Icons.photo_camera_outlined,
                    label: "Caméra",
                    onTap: () => _pickFrom(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _photoButton(
                    icon: Icons.photo_library_outlined,
                    label: "Galerie",
                    onTap: () => _pickFrom(ImageSource.gallery),
                  ),
                ),
              ],
            ),

            _sectionTitle("Bibliothèque SignCi"),
            SizedBox(
              height: 96,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: CreerAnnoncePage.libImages.map((asset) {
                  final selected = _imagePath == asset;
                  return GestureDetector(
                    onTap: () => setState(() => _imagePath = asset),
                    child: Container(
                      width: 96,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: selected
                            ? Border.all(color: const Color(0xFF0275D8), width: 3)
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              asset,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported_outlined,
                                    color: Colors.grey),
                              ),
                            ),
                            if (selected)
                              Container(
                                color: const Color(0xFF0275D8).withValues(alpha: 0.3),
                                child: const Icon(Icons.check_circle,
                                    color: Colors.white),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0275D8),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isPublishing ? null : _publish,
                icon: isPublishing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.campaign, color: Colors.white),
                label: Text(
                  isPublishing ? "Publication..." : "Publier l'annonce",
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _photoButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: const Color(0xFF0275D8)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}