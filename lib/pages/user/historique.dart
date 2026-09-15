import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/signalement_model.dart';
import '../../services/ai_service.dart';
import '../../services/supabase_service.dart';

class HistoriquePage extends StatefulWidget {
  const HistoriquePage({super.key});

  @override
  State<HistoriquePage> createState() => _HistoriquePageState();
}

class _HistoriquePageState extends State<HistoriquePage> {
  List<SignalementModel> data = [];
  Map<int, bool> criticalMap = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final res = await SupabaseService.getAllSignalements();
    final criticals = AIService.evaluateCriticalZones(res);

    if (mounted) {
      setState(() {
        data = res;
        criticalMap = criticals;
        isLoading = false;
      });
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case "En cours":
        return Colors.orange;
      case "Résolu":
        return Colors.green;
      default:
        return const Color(0xFF0275D8);
    }
  }

  Widget postCard(SignalementModel s) {
    List<String> images = [];

    if (s.image.isNotEmpty) {
      images = s.image.split(";");
    }

    bool isCritical = criticalMap[s.id] ?? s.isCriticalZone;

    Widget buildImage(String img) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: img.startsWith("http")
            ? Image.network(img, fit: BoxFit.cover, errorBuilder: (c, e, st) => const Icon(Icons.broken_image))
            : Image.file(File(img), fit: BoxFit.cover, errorBuilder: (c, e, st) => const Icon(Icons.broken_image)),
      );
    }

    Widget imageLayout() {
      if (images.isEmpty) return const SizedBox();

      if (images.length == 1) {
        return SizedBox(
          height: 180,
          width: double.infinity,
          child: buildImage(images[0]),
        );
      }

      if (images.length == 2) {
        return SizedBox(
          height: 160,
          child: Row(
            children: images.map((img) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: buildImage(img),
                ),
              );
            }).toList(),
          ),
        );
      }

      return SizedBox(
        height: 180,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: images.length > 4 ? 4 : images.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemBuilder: (_, i) {
            if (i == 3 && images.length > 4) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  buildImage(images[i]),
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Text(
                        "+${images.length - 4}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return buildImage(images[i]);
          },
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor(s.status).withValues(alpha: 0.2),
                  child: Icon(Icons.person, color: statusColor(s.status)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${s.type} • ${s.categorie}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        s.adresse.isNotEmpty ? s.adresse : "Adresse non spécifiée",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                /// STATUS BADGE
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor(s.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    s.status,
                    style: TextStyle(
                      color: statusColor(s.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            /// PROBLEME & BADGES
            Row(
              children: [
                Expanded(
                  child: Text(
                    "🚨 ${s.probleme}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                if (isCritical)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red),
                    ),
                    child: const Text("ZONE CRITIQUE 🚨", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            /// DESCRIPTION
            Text(s.description, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 10),

            /// IA BADGES
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.psychology, size: 16, color: Color(0xFF0275D8)),
                  label: Text("Confiance IA : ${(s.confidenceScore * 100).toInt()}%"),
                  backgroundColor: const Color(0xFF0275D8).withValues(alpha: 0.08),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  avatar: Icon(Icons.flag, size: 16, color: s.priorite == "Haute" ? Colors.red : Colors.orange),
                  label: Text("Priorité : ${s.priorite}"),
                  backgroundColor: Colors.grey[100],
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 10),

            /// IMAGES
            imageLayout(),

            const Divider(height: 24),

            /// CITIZEN UPVOTE ACTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "👍 ${s.upvotesCount} confirmation(s)",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0275D8)),
                ),
                TextButton.icon(
                  onPressed: () async {
                    if (s.id != null) {
                      await SupabaseService.upvote(s.id!);
                      load();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Signalement confirmé (+1 Vote) 👍")),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.thumb_up_outlined, size: 18),
                  label: const Text("Je confirme ce problème"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historique des Signalements"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: load,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : data.isEmpty
                    ? const Center(
                        child: Text("Aucun signalement pour le moment.\nCréez-en un avec le bouton 'Signaler' ! 🚀", textAlign: TextAlign.center),
                      )
                    : RefreshIndicator(
                        onRefresh: load,
                        child: ListView.builder(
                          itemCount: data.length,
                          itemBuilder: (c, i) => postCard(data[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}