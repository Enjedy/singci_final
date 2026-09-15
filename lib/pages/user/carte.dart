import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/signalement_model.dart';
import '../../services/ai_service.dart';
import '../../services/location_service.dart';
import '../../services/supabase_service.dart';

class CarteSignalementPage extends StatefulWidget {
  const CarteSignalementPage({super.key});

  @override
  State<CarteSignalementPage> createState() => _CarteSignalementPageState();
}

class _CarteSignalementPageState extends State<CarteSignalementPage> {
  List<SignalementModel> incidents = [];
  Map<int, bool> criticalZonesMap = {};
  bool isLoading = true;
  String selectedFilter = "Tous"; // "Tous", "Haute", "Zones Critiques"

  // Position utilisateur (GPS ou fallback Antananarivo)
  final MapController _mapController = MapController();
  double? userLat;
  double? userLng;

  // Bornes d'Antananarivo
  static final LatLngBounds tanaBounds = LatLngBounds(
    const LatLng(LocationService.minLat, LocationService.minLng),
    const LatLng(LocationService.maxLat, LocationService.maxLng),
  );

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadReports(),
      _loadUserLocation(),
    ]);
  }

  Future<void> _loadReports() async {
    final data = await SupabaseService.getAllSignalements();
    final criticals = AIService.evaluateCriticalZones(data, radiusKm: 0.5, minReportsThreshold: 3);

    if (mounted) {
      setState(() {
        incidents = data.where((r) => r.latitude != null && r.longitude != null).toList();
        criticalZonesMap = criticals;
        isLoading = false;
      });
    }
  }

  Future<void> _loadUserLocation() async {
    final loc = await LocationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        userLat = loc.latitude;
        userLng = loc.longitude;
      });
      _mapController.move(LatLng(loc.latitude, loc.longitude), 14);
    }
  }

  Color getColor(String? priorite, bool isCritical) {
    if (isCritical) return Colors.redAccent;
    switch (priorite?.toLowerCase()) {
      case "haute":
      case "haut":
        return Colors.red;
      case "moyenne":
        return Colors.orange;
      case "basse":
        return Colors.green;
      default:
        return const Color(0xFF0275D8);
    }
  }

  List<SignalementModel> get filteredIncidents {
    if (selectedFilter == "Haute") {
      return incidents.where((e) => e.priorite.toLowerCase() == "haute" || e.priorite.toLowerCase() == "haut").toList();
    } else if (selectedFilter == "Zones Critiques") {
      return incidents.where((e) => criticalZonesMap[e.id] == true).toList();
    }
    return incidents;
  }

  void _showReportDetails(SignalementModel report) {
    bool isCritical = criticalZonesMap[report.id] ?? false;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "🚨 ${report.probleme}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: getColor(report.priorite, isCritical).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isCritical ? "ZONE CRITIQUE" : report.priorite,
                      style: TextStyle(
                        color: getColor(report.priorite, isCritical),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text("Type: ${report.type} • Catégorie: ${report.categorie}", style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              Text(report.description),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(child: Text(report.adresse, style: const TextStyle(fontSize: 12))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0275D8).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Confiance IA: ${(report.confidenceScore * 100).toInt()}%",
                      style: const TextStyle(color: Color(0xFF0275D8), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text("👍 ${report.upvotesCount} vote(s)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0275D8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    if (report.id != null) {
                      await SupabaseService.upvote(report.id!);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadReports();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Signalement confirmé (+1 Vote)")),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.thumb_up, color: Colors.white, size: 18),
                  label: const Text("Je confirme ce problème (+1 Vote)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final criticalReports = incidents.where((e) => criticalZonesMap[e.id] == true && e.latitude != null && e.longitude != null).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Carte Intelligente SignCi"),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: "Ma position",
            onPressed: _loadUserLocation,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAll,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(
                      userLat ?? LocationService.defaultLat,
                      userLng ?? LocationService.defaultLng,
                    ),
                    initialZoom: 13,
                    minZoom: 11,
                    maxZoom: 18,
                    cameraConstraint: CameraConstraint.contain(bounds: tanaBounds),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    CircleLayer(
                      circles: criticalReports.map((r) {
                        return CircleMarker(
                          point: LatLng(r.latitude!, r.longitude!),
                          color: Colors.red.withValues(alpha: 0.25),
                          borderColor: Colors.red,
                          borderStrokeWidth: 2,
                          useRadiusInMeter: true,
                          radius: 500,
                        );
                      }).toList(),
                    ),
                    MarkerLayer(
                      markers: [
                        // Position utilisateur
                        if (userLat != null && userLng != null)
                          Marker(
                            point: LatLng(userLat!, userLng!),
                            width: 36,
                            height: 36,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black26, blurRadius: 6),
                                ],
                              ),
                              child: const Icon(Icons.person, color: Colors.white, size: 20),
                            ),
                          ),

                        // Incidents
                        ...filteredIncidents
                            .where((e) => e.latitude != null && e.longitude != null)
                            .map((incident) {
                          bool isCritical = criticalZonesMap[incident.id] ?? false;
                          return Marker(
                            point: LatLng(incident.latitude!, incident.longitude!),
                            width: 45,
                            height: 45,
                            child: GestureDetector(
                              onTap: () => _showReportDetails(incident),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: getColor(incident.priorite, isCritical).withValues(alpha: 0.5),
                                      blurRadius: isCritical ? 12 : 6,
                                      spreadRadius: isCritical ? 3 : 1,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isCritical ? Icons.warning_amber_rounded : Icons.location_on,
                                  color: getColor(incident.priorite, isCritical),
                                  size: isCritical ? 30 : 26,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  top: 15,
                  left: 15,
                  right: 15,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ["Tous", "Haute", "Zones Critiques"].map((filter) {
                        bool isSelected = selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              filter == "Zones Critiques" ? "Zones Critiques" : filter,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: const Color(0xFF0275D8),
                            backgroundColor: Colors.white,
                            elevation: 4,
                            onSelected: (val) {
                              setState(() {
                                selectedFilter = filter;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}