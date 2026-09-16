import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/annonce_model.dart';
import '../../services/supabase_service.dart';
import '../admin/creer_annonce_page.dart';

/// Fil d'actualités des annonces publiées par l'administration SignCi.
/// Design inspiré des publications Facebook (photo, likes, commentaires, partage).
class AnnoncePage extends StatefulWidget {
  const AnnoncePage({super.key});

  /// Code d'accès au mode administrateur (publication / suppression d'annonces).
  static const String adminPin = 'admin2026';

  @override
  State<AnnoncePage> createState() => _AnnoncePageState();
}

class _AnnoncePageState extends State<AnnoncePage> {
  List<AnnonceModel> annonces = [];
  Map<int, List<AnnonceComment>> commentsByAnnonce = {};
  final Set<int> _likedIds = {};
  bool isLoading = true;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadLikedFromPrefs();
    _loadAll();
  }

  Future<void> _loadLikedFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('annonce_liked_ids') ?? [];
    if (mounted) {
      setState(() => _likedIds
        ..clear()
        ..addAll(saved.map(int.parse)));
    }
  }

  Future<void> _saveLikedToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'annonce_liked_ids',
      _likedIds.map((e) => e.toString()).toList(),
    );
  }

  Future<void> _loadAll() async {
    _loadAnnonces();
  }

  Future<void> _loadAnnonces() async {
    try {
      final data = await SupabaseService.getAllAnnonces();
      final comments = await SupabaseService.getAllAnnonceComments();
      final grouped = <int, List<AnnonceComment>>{};
      for (final c in comments) {
        grouped.putIfAbsent(c.annonceId, () => []).add(c);
      }
      if (mounted) {
        setState(() {
          annonces = data;
          commentsByAnnonce = grouped;
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Impossible de charger les annonces. Vérifiez la connexion."),
          ),
        );
      }
    }
  }

  // ============================ ACTIONS ============================

  void _toggleAdminMode() {
    if (isAdmin) {
      setState(() => isAdmin = false);
      return;
    }

    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Color(0xFF0275D8), size: 28),
            SizedBox(width: 8),
            Expanded(child: Text("Accès Administrateur", style: TextStyle(fontSize: 18))),
          ],
        ),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: "Code d'administration",
            prefixIcon: Icon(Icons.lock_outline),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0275D8)),
            onPressed: () {
              if (controller.text.trim() == AnnoncePage.adminPin) {
                Navigator.pop(ctx);
                if (mounted) {
                  setState(() => isAdmin = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Mode administrateur activé ✅")),
                  );
                }
              } else {
                Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Code incorrect, accès refusé ❌")),
                  );
                }
              }
            },
            child: const Text("Se connecter"),
          ),
        ],
      ),
    );
  }

  Future<void> _openCreateAnnonce() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreerAnnoncePage()),
    );
    if (created == true && mounted) {
      setState(() => isLoading = true);
      _loadAnnonces();
    }
  }

  Future<void> _deleteAnnonce(AnnonceModel annonce) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Supprimer cette annonce ?"),
        content: Text("« ${annonce.titre} » sera définitivement retiré du fil."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );

    if (confirmed != true || annonce.id == null) return;
    await SupabaseService.deleteAnnonce(annonce.id!);
    if (mounted) {
      setState(() {
        annonces.removeWhere((e) => e.id == annonce.id);
        commentsByAnnonce.remove(annonce.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Annonce supprimée 🗑️")),
      );
    }
  }

  // ============================ LIKES ============================

  Future<void> _toggleLike(AnnonceModel annonce) async {
    if (annonce.id == null) return;
    final isLiked = _likedIds.contains(annonce.id);
    final delta = isLiked ? -1 : 1;

    setState(() {
      if (isLiked) {
        _likedIds.remove(annonce.id);
      } else {
        _likedIds.add(annonce.id!);
      }
      final index = annonces.indexWhere((e) => e.id == annonce.id);
      if (index != -1) {
        final current = annonces[index];
        annonces[index] = AnnonceModel(
          id: current.id,
          titre: current.titre,
          description: current.description,
          image: current.image,
          auteur: current.auteur,
          datePublication: current.datePublication,
          likes: (current.likes + delta).clamp(0, 1 << 31).toInt(),
        );
      }
    });
    await _saveLikedToPrefs();
    await SupabaseService.addLikeAnnonce(annonce.id!, delta);
  }

  // ============================ COMMENTAIRES ============================

  void _openComments(AnnonceModel annonce) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CommentsSheet(
        annonce: annonce,
        initialComments: commentsByAnnonce[annonce.id] ?? [],
        onAdd: (comment) async {
          await SupabaseService.insertAnnonceComment(comment);
        },
        onCommentAdded: (AnnonceComment c) {
          if (mounted) {
            setState(() {
              commentsByAnnonce.putIfAbsent(c.annonceId, () => []).insert(0, c);
            });
          }
        },
      ),
    );
  }

  // ============================ UI ============================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Annonces & Actualités"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Actualiser",
            onPressed: _loadAll,
          ),
          IconButton(
            icon: Icon(
              isAdmin ? Icons.admin_panel_settings : Icons.shield_outlined,
              color: isAdmin ? Colors.amber : null,
            ),
            tooltip: isAdmin
                ? "Mode administrateur (quitter)"
                : "Accès administrateur",
            onPressed: _toggleAdminMode,
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF0275D8),
              onPressed: _openCreateAnnonce,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Publier",
                  style: TextStyle(color: Colors.white)),
            )
          : null,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : annonces.isEmpty
              ? _EmptyState(isAdmin: isAdmin, onPublish: _openCreateAnnonce)
              : RefreshIndicator(
                  onRefresh: _loadAnnonces,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: annonces.length,
                    itemBuilder: (context, index) {
                      final annonce = annonces[index];
                      return _AnnonceCard(
                        annonce: annonce,
                        isAdmin: isAdmin,
                        isLiked: _likedIds.contains(annonce.id),
                        commentCount:
                            commentsByAnnonce[annonce.id]?.length ?? 0,
                        onLike: () => _toggleLike(annonce),
                        onComment: () => _openComments(annonce),
                        onDelete: () => _deleteAnnonce(annonce),
                      );
                    },
                  ),
                ),
    );
  }
}

/// Affiche l'image d'une annonce (asset local, URL http ou chemin de fichier).
Widget buildAnnonceImage(String image, {double? height}) {
  final Widget fallback = Container(
    height: height ?? 240,
    color: Colors.grey[200],
    child: const Center(
      child: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
    ),
  );

  if (image.isEmpty) return const SizedBox.shrink();

  if (image.startsWith('assets/')) {
    return Image.asset(
      image,
      height: height ?? 240,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (c, e, s) => fallback,
    );
  }
  if (image.startsWith('http')) {
    return Image.network(
      image,
      height: height ?? 240,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (c, e, s) => fallback,
    );
  }
  return Image.file(
    File(image),
    height: height ?? 240,
    width: double.infinity,
    fit: BoxFit.cover,
    errorBuilder: (c, e, s) => fallback,
  );
}

/// Formate une date en texte relatif ("il y a 3 heures").
String formatAnnonceDate(String iso) {
  final date = DateTime.tryParse(iso)?.toLocal();
  if (date == null) return "";
  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.inSeconds < 60) return "à l'instant";
  if (diff.inMinutes < 60) return "il y a ${diff.inMinutes} min";
  if (diff.inHours < 24) return "il y a ${diff.inHours} h";
  if (diff.inDays < 7) return "il y a ${diff.inDays} j";
  return "${date.day.toString().padLeft(2, '0')}/"
      "${date.month.toString().padLeft(2, '0')}/"
      "${date.year}";
}

/// Carte d'une annonce au style Facebook.
class _AnnonceCard extends StatefulWidget {
  final AnnonceModel annonce;
  final bool isAdmin;
  final bool isLiked;
  final int commentCount;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onDelete;

  const _AnnonceCard({
    required this.annonce,
    required this.isAdmin,
    required this.isLiked,
    required this.commentCount,
    required this.onLike,
    required this.onComment,
    required this.onDelete,
  });

  @override
  State<_AnnonceCard> createState() => _AnnonceCardState();
}

class _AnnonceCardState extends State<_AnnonceCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final annonce = widget.annonce;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------- EN-TÊTE (style Facebook) --------
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 6, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF0275D8).withValues(alpha: 0.15),
                  child: const Icon(Icons.campaign,
                      color: Color(0xFF0275D8), size: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        annonce.auteur,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const Text(
                        "Ville · Actualité SignCi",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatAnnonceDate(annonce.datePublication),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                if (widget.isAdmin) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: "Supprimer",
                    visualDensity: VisualDensity.compact,
                    onPressed: widget.onDelete,
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),

          // -------- IMAGE --------
          if (annonce.image.isNotEmpty) buildAnnonceImage(annonce.image),

          // -------- CONTENU --------
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  annonce.titre,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  annonce.description,
                  maxLines: _expanded ? null : 4,
                  overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                if (annonce.description.length > 160)
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        _expanded ? "Voir moins" : "Voir plus",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // -------- ACTIONS (Like / Commentaire / Partage) --------
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
            child: Row(
              children: [
                _ActionButton(
                  icon: widget.isLiked
                      ? Icons.thumb_up
                      : Icons.thumb_up_outlined,
                  iconColor:
                      widget.isLiked ? const Color(0xFF0275D8) : null,
                  label: "J'aime",
                  count: annonce.likes,
                  onTap: widget.onLike,
                ),
                _ActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: "Commenter",
                  count: widget.commentCount,
                  onTap: widget.onComment,
                ),
                _ActionButton(
                  icon: Icons.share_outlined,
                  label: "Partager",
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text("Lien de l'annonce copié dans le presse-papier 📋")),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final int? count;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    this.iconColor,
    required this.label,
    this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: iconColor ?? Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                count == null ? label : "$label ($count)",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: iconColor ?? Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Feuille en bas pour lire et poster des commentaires.
class _CommentsSheet extends StatefulWidget {
  final AnnonceModel annonce;
  final List<AnnonceComment> initialComments;
  final Future<void> Function(AnnonceComment comment) onAdd;
  final void Function(AnnonceComment comment) onCommentAdded;

  const _CommentsSheet({
    required this.annonce,
    required this.initialComments,
    required this.onAdd,
    required this.onCommentAdded,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  late List<AnnonceComment> comments;
  final TextEditingController controller = TextEditingController();
  bool sending = false;

  @override
  void initState() {
    super.initState();
    comments = List.of(widget.initialComments);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = controller.text.trim();
    if (text.isEmpty || sending) return;
    setState(() => sending = true);

    final comment = AnnonceComment(
      annonceId: widget.annonce.id ?? 0,
      pseudo: "Citoyen SignCi",
      contenu: text,
    );
    await widget.onAdd(comment);

    if (mounted) {
      setState(() {
        comments.insert(0, comment);
        controller.clear();
        sending = false;
      });
      widget.onCommentAdded(comment);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline,
                      color: Color(0xFF0275D8), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "${comments.length} commentaire(s) — ${widget.annonce.titre}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: comments.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        children: [
                          Icon(Icons.forum_outlined,
                              size: 40, color: Colors.grey[400]),
                          const SizedBox(height: 10),
                          const Text(
                            "Aucun commentaire pour l'instant.",
                            style: TextStyle(color: Colors.grey),
                          ),
                          const Text(
                            "Soyez le premier à réagir !",
                            style: TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final c = comments[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFF0275D8)
                                    .withValues(alpha: 0.15),
                                child: const Icon(Icons.person,
                                    size: 16, color: Color(0xFF0275D8)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF2A2A2A)
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.pseudo,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(c.contenu,
                                          style: const TextStyle(fontSize: 14)),
                                      const SizedBox(height: 4),
                                      Text(
                                        formatAnnonceDate(c.createdAt),
                                        style: TextStyle(
                                            fontSize: 11, color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            // -------- Champ de saisie --------
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFF0275D8),
                    child: Icon(Icons.person, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Écrire un commentaire...",
                        filled: true,
                        fillColor:
                            isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send, color: Color(0xFF0275D8)),
                    onPressed: sending ? null : _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isAdmin;
  final VoidCallback onPublish;

  const _EmptyState({required this.isAdmin, required this.onPublish});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: const Color(0xFF0275D8).withValues(alpha: 0.1),
            child: const Icon(Icons.campaign_outlined,
                size: 46, color: Color(0xFF0275D8)),
          ),
          const SizedBox(height: 20),
          const Text(
            "Aucune annonce publiée",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              isAdmin
                  ? "Cliquez sur « Publier » pour annoncer une actualité."
                  : "Les actualités de la municipalité apparaîtront ici.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.5),
            ),
          ),
          if (isAdmin) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0275D8),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onPublish,
              icon: const Icon(Icons.add),
              label: const Text("Publier une annonce",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }
}