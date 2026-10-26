import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/app_flavor.dart';
import '../../explore/data/mock_pe_data.dart';
import '../../explore/presentation/explore_controller.dart';
import '../../trip_planner/domain/itinerary_models.dart';
import '../../trip_planner/domain/trip_request.dart';
import '../../trip_planner/presentation/trip_planner_controller.dart';
import '../../trip_planner/services/local_db_service.dart';
import '../../trip_planner/services/trip_optimizer_service.dart';
import '../../social/services/social_service.dart';

class MapScreen extends ConsumerStatefulWidget {
  final String? initialFilter;
  final String? initialAttractionId;
  final double? initialLat;
  final double? initialLon;

  const MapScreen({
    super.key,
    this.initialFilter,
    this.initialAttractionId,
    this.initialLat,
    this.initialLon,
  });

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  AttractionModel? _selectedAttraction;
  String _selectedCityFilter = 'todos';
  int? _selectedDayFilter; // null = Todos os dias do roteiro
  String _searchQuery = '';

  // Posição de referência do usuário (Marco Zero / GPS)
  static const LatLng _userLocation = LatLng(-8.0631, -34.8711);

  // Coordenadas centrais das cidades polo de Pernambuco
  static const Map<String, LatLng> _cityCenters = {
    'near': LatLng(-8.0631, -34.8711),
    'todos': LatLng(-8.0631, -34.8711),
    'recife': LatLng(-8.0631, -34.8711),
    'porto_de_galinhas': LatLng(-8.5042, -35.0028),
    'olinda': LatLng(-8.0139, -34.8519),
    'carneiros': LatLng(-8.7042, -35.0883),
    'noronha': LatLng(-3.8549, -32.4297),
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null && widget.initialFilter!.isNotEmpty) {
      _selectedCityFilter = widget.initialFilter!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialLat != null && widget.initialLon != null) {
        final target = LatLng(widget.initialLat!, widget.initialLon!);
        _mapController.move(target, 15.5);
        final allAttractions = ref.read(curatedAttractionsProvider).value ?? MockPeData.topAttractions;
        if (widget.initialAttractionId != null) {
          final found = allAttractions.where((a) => a.id == widget.initialAttractionId).firstOrNull;
          if (found != null && mounted) {
            setState(() {
              _selectedAttraction = found;
            });
          }
        }
      } else if (_selectedCityFilter == 'roteiro') {
        _ensureActivePlanLoaded();
      }
    });
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFilter != null && widget.initialFilter != oldWidget.initialFilter) {
      setState(() {
        _selectedCityFilter = widget.initialFilter!;
        _selectedDayFilter = null;
      });
      if (widget.initialFilter == 'roteiro') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _ensureActivePlanLoaded();
        });
      }
    }
    if (widget.initialLat != null && widget.initialLon != null &&
        (widget.initialLat != oldWidget.initialLat ||
         widget.initialLon != oldWidget.initialLon ||
         widget.initialAttractionId != oldWidget.initialAttractionId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = LatLng(widget.initialLat!, widget.initialLon!);
        _mapController.move(target, 15.5);
        final allAttractions = ref.read(curatedAttractionsProvider).value ?? MockPeData.topAttractions;
        if (widget.initialAttractionId != null) {
          final found = allAttractions.where((a) => a.id == widget.initialAttractionId).firstOrNull;
          if (found != null && mounted) {
            setState(() {
              _selectedAttraction = found;
            });
          }
        }
      });
    }
  }

  void _ensureActivePlanLoaded() {
    final current = ref.read(currentTripPlanProvider).value;
    if (current != null && current.days.isNotEmpty) {
      final stops = current.days.expand((d) => d.stops).toList();
      final firstStop = stops.firstOrNull;
      if (firstStop != null && mounted) {
        setState(() {
          _selectedAttraction = firstStop.place.toAttractionModel();
        });
        _fitBoundsForStops(stops);
      }
      return;
    }

    // Carrega o roteiro salvo mais recente ou gera o padrão sugerido
    ref.read(localDbServiceProvider).getSavedTrips().then((trips) {
      if (!mounted) return;
      if (trips.isNotEmpty) {
        ref.read(currentTripPlanProvider.notifier).loadTripById(trips.first.id).then((_) {
          if (!mounted) return;
          final loaded = ref.read(currentTripPlanProvider).value;
          if (loaded != null && loaded.days.isNotEmpty) {
            final stops = loaded.days.expand((d) => d.stops).toList();
            final firstStop = stops.firstOrNull;
            if (firstStop != null) {
              setState(() {
                _selectedAttraction = firstStop.place.toAttractionModel();
              });
              _fitBoundsForStops(stops);
            }
          }
        });
      } else {
        ref.read(currentTripPlanProvider.notifier).generateTrip(
          const TripRequest(cityName: 'Recife', days: 3),
        ).then((generated) {
          if (!mounted || generated == null || generated.days.isEmpty) return;
          final stops = generated.days.expand((d) => d.stops).toList();
          final firstStop = stops.firstOrNull;
          if (firstStop != null) {
            setState(() {
              _selectedAttraction = firstStop.place.toAttractionModel();
            });
            _fitBoundsForStops(stops);
          }
        });
      }
    });
  }

  void _fitBoundsForStops(List<ItineraryStop> stops) {
    if (stops.isEmpty) return;
    final points = stops.map((s) => LatLng(s.place.lat, s.place.lon)).toList();

    if (points.length == 1) {
      _mapController.move(points.first, 15.5);
      return;
    }

    try {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.only(top: 220, bottom: 200, left: 50, right: 50),
          maxZoom: 16.0,
          minZoom: 11.5,
        ),
      );
    } catch (_) {
      _mapController.move(points.first, 14.5);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterRoteiroDay(int? dayNumber, TripPlan plan) {
    setState(() {
      _selectedCityFilter = 'roteiro';
      _selectedDayFilter = dayNumber;
      _searchQuery = '';
      _searchController.clear();
    });

    final stops = dayNumber == null
        ? plan.days.expand((d) => d.stops).toList()
        : (plan.days.where((d) => d.dayNumber == dayNumber).isNotEmpty
            ? plan.days.firstWhere((d) => d.dayNumber == dayNumber).stops
            : plan.days.expand((d) => d.stops).toList());

    if (stops.isNotEmpty) {
      final firstStop = stops.first;
      setState(() {
        _selectedAttraction = firstStop.place.toAttractionModel();
      });
      _fitBoundsForStops(stops);
    }
  }

  void _filterCity(String cityKey, {TripPlan? activePlan}) {
    setState(() {
      _selectedCityFilter = cityKey;
      _selectedDayFilter = null;
      _searchQuery = '';
      _searchController.clear();
    });

    final allAttractions = ref.read(curatedAttractionsProvider).value ?? MockPeData.topAttractions;

    if (cityKey == 'near') {
      _mapController.move(_userLocation, 14.5);
      final sorted = List<AttractionModel>.from(allAttractions)
        ..sort((a, b) {
          final distA = TripOptimizerService.calculateDistanceMeters(
            _userLocation.latitude, _userLocation.longitude, a.lat, a.lon);
          final distB = TripOptimizerService.calculateDistanceMeters(
            _userLocation.latitude, _userLocation.longitude, b.lat, b.lon);
          return distA.compareTo(distB);
        });
      if (sorted.isNotEmpty) {
        setState(() => _selectedAttraction = sorted.first);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📍 Mostrando atrações mais próximas de você!'),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF0F4C81),
        ),
      );
      return;
    }

    if (cityKey == 'roteiro') {
      final plan = activePlan ?? ref.read(currentTripPlanProvider).value;
      if (plan != null && plan.days.isNotEmpty) {
        final stops = plan.days.expand((d) => d.stops).toList();
        final firstStop = stops.firstOrNull;
        if (firstStop != null) {
          setState(() {
            _selectedDayFilter = null;
            _selectedAttraction = firstStop.place.toAttractionModel();
          });
          _fitBoundsForStops(stops);
          return;
        }
      }
      _ensureActivePlanLoaded();
      return;
    }

    final cityAttractions = allAttractions
        .where((a) => a.cityId.toLowerCase().contains(cityKey))
        .toList();
    if (cityAttractions.isNotEmpty) {
      setState(() => _selectedAttraction = cityAttractions.first);
    }

    final target = _cityCenters[cityKey] ?? _cityCenters['todos']!;
    final zoom = cityKey == 'noronha' ? 12.5 : (cityKey == 'todos' ? 11.5 : 14.0);
    _mapController.move(target, zoom);
  }

  void _performSearch(String query) {
    final cleanQuery = query.toLowerCase().trim();
    setState(() => _searchQuery = cleanQuery);

    if (cleanQuery.isNotEmpty) {
      final allAttractions = ref.read(curatedAttractionsProvider).value ?? MockPeData.topAttractions;
      final matches = allAttractions.where((a) =>
        a.name.toLowerCase().contains(cleanQuery) ||
        a.cityName.toLowerCase().contains(cleanQuery) ||
        a.category.toLowerCase().contains(cleanQuery) ||
        a.description.toLowerCase().contains(cleanQuery),
      ).toList();

      if (matches.isNotEmpty) {
        final match = matches.first;
        setState(() => _selectedAttraction = match);
        _mapController.move(LatLng(match.lat, match.lon), 15.0);
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('praia') || cat.contains('litoral') || cat.contains('mar')) {
      return Icons.beach_access;
    } else if (cat.contains('cultura') || cat.contains('hist') || cat.contains('museu')) {
      return Icons.account_balance;
    } else if (cat.contains('gastro') || cat.contains('restaurante')) {
      return Icons.restaurant;
    } else if (cat.contains('igreja') || cat.contains('relig')) {
      return Icons.church;
    } else if (cat.contains('aventura') || cat.contains('trilha') || cat.contains('natureza')) {
      return Icons.landscape;
    }
    return Icons.place;
  }

  String _resolveAttractionImage(String name, String category, String url) {
    if (url.isNotEmpty && (url.startsWith('http') || url.startsWith('assets/'))) {
      return url;
    }
    final n = name.toLowerCase();
    final cat = category.toLowerCase();
    if (n.contains('marco zero') || n.contains('recife')) {
      return 'https://images.unsplash.com/photo-1680788842764-b5c9bc78ce59?auto=format&fit=crop&w=400&q=80';
    } else if (n.contains('porto') || n.contains('jangada') || n.contains('piscina') || cat.contains('praia')) {
      return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=400&q=80';
    } else if (n.contains('olinda') || n.contains('sé') || n.contains('mirante') || cat.contains('cultura')) {
      return 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=400&q=80';
    } else if (n.contains('carneiros') || n.contains('benedito') || n.contains('igreja')) {
      return 'https://images.unsplash.com/photo-1519046904884-53103b34b206?auto=format&fit=crop&w=400&q=80';
    } else if (n.contains('sancho') || n.contains('noronha')) {
      return 'https://images.unsplash.com/photo-1518509562904-e7ef99cdcc86?auto=format&fit=crop&w=400&q=80';
    } else if (cat.contains('gastro') || cat.contains('restaurante')) {
      return 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=400&q=80';
    }
    return 'https://images.unsplash.com/photo-1577039508937-99c3b639ba77?auto=format&fit=crop&w=400&q=80';
  }

  List<Marker> _buildDispersedRouteMarkers({
    required List<ItineraryStop> routeStops,
    required String? selectedAttractionId,
    required FlavorConfig config,
    required bool isDark,
  }) {
    if (routeStops.isEmpty) return const [];

    final List<Marker> markers = [];
    final List<LatLng> computedPositions = [];

    for (int i = 0; i < routeStops.length; i++) {
      final stop = routeStops[i];
      final originalPos = LatLng(stop.place.lat, stop.place.lon);

      // Agrupa paradas que estão a menos de ~120m (0.0012 graus)
      int clusterCount = 0;
      int clusterIndex = 0;
      for (int j = 0; j < computedPositions.length; j++) {
        final distLat = (computedPositions[j].latitude - originalPos.latitude).abs();
        final distLon = (computedPositions[j].longitude - originalPos.longitude).abs();
        if (distLat < 0.0012 && distLon < 0.0012) {
          clusterCount++;
          clusterIndex = clusterCount;
        }
      }

      LatLng effectivePos = originalPos;
      if (clusterIndex > 0) {
        // Aplica leque radial para que nenhum pin cubra o outro
        final angle = (clusterIndex * (2 * math.pi / 5)) - (math.pi / 2);
        const offsetRadius = 0.00075; // ~80m de raio visual no mapa
        effectivePos = LatLng(
          originalPos.latitude + offsetRadius * math.sin(angle),
          originalPos.longitude + offsetRadius * math.cos(angle) * 1.25,
        );
      }
      computedPositions.add(effectivePos);

      final idx = i + 1;
      final isSelected = selectedAttractionId == stop.place.id;

      markers.add(
        Marker(
          point: effectivePos,
          width: isSelected ? 66 : 54,
          height: isSelected ? 74 : 62,
          alignment: Alignment.bottomCenter,
          child: _buildPhotoMarker(
            name: stop.place.name,
            imageUrl: stop.place.imageUrl,
            category: stop.place.category,
            rating: stop.place.ratingAvg,
            isSelected: isSelected,
            primaryColor: config.primaryColor,
            secondaryColor: config.secondaryColor,
            isDark: isDark,
            stepIndex: idx,
            onTap: () {
              setState(() {
                _selectedAttraction = stop.place.toAttractionModel();
              });
              _mapController.move(effectivePos, 16.0);
            },
          ),
        ),
      );
    }

    // Marcador selecionado é renderizado por último (fica na frente de todos)
    markers.sort((a, b) {
      if (a.width > 60) return 1;
      if (b.width > 60) return -1;
      return 0;
    });

    return markers;
  }

  Widget _buildPhotoMarker({
    required String name,
    required String imageUrl,
    required String category,
    required double rating,
    required bool isSelected,
    required Color primaryColor,
    required Color secondaryColor,
    required bool isDark,
    int? stepIndex,
    required VoidCallback onTap,
  }) {
    final double avatarSize = isSelected ? 48.0 : 40.0;
    final double markerWidth = isSelected ? 62.0 : 50.0;
    final double markerHeight = isSelected ? 70.0 : 58.0;
    final effectiveImageUrl = _resolveAttractionImage(name, category, imageUrl);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: markerWidth,
        height: markerHeight,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // Sombra no chão (onde a ponta toca o mapa)
            Positioned(
              bottom: 1,
              child: Container(
                width: 14,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Triângulo / Ponta Inferior do Pin
            Positioned(
              bottom: 4,
              child: Transform.rotate(
                angle: 0.785398, // 45 graus
                child: Container(
                  width: isSelected ? 14 : 11,
                  height: isSelected ? 14 : 11,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (stepIndex != null ? Colors.deepOrange : secondaryColor)
                        : (stepIndex != null ? Colors.orange.shade700 : (isDark ? const Color(0xFF1E293B) : Colors.white)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 3,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Círculo Principal com a Foto Miniatura
            Positioned(
              bottom: 10,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? (stepIndex != null ? Colors.deepOrange : secondaryColor)
                        : (stepIndex != null ? Colors.orange.shade600 : (isDark ? const Color(0xFF334155) : Colors.white)),
                    width: isSelected ? 3.0 : 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? (stepIndex != null ? Colors.deepOrange.withValues(alpha: 0.5) : secondaryColor.withValues(alpha: 0.5))
                          : Colors.black.withValues(alpha: 0.28),
                      blurRadius: isSelected ? 10 : 6,
                      offset: const Offset(0, 3),
                      spreadRadius: isSelected ? 1.5 : 0,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: effectiveImageUrl.startsWith('assets/')
                      ? Image.asset(
                          effectiveImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackCategoryIcon(category, primaryColor),
                        )
                      : Image.network(
                          effectiveImageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return _buildFallbackCategoryIcon(category, primaryColor);
                          },
                          errorBuilder: (_, __, ___) => _buildFallbackCategoryIcon(category, primaryColor),
                        ),
                ),
              ),
            ),

            // Selo de Nota (⭐ 4.9) ou Número da Parada no Roteiro (1, 2, 3...)
            Positioned(
              top: 0,
              right: stepIndex != null ? null : (isSelected ? 2 : 0),
              left: stepIndex != null ? 0 : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: stepIndex != null
                        ? [Colors.orange.shade700, Colors.deepOrange]
                        : [const Color(0xFF0F172A), const Color(0xFF1E293B)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: stepIndex != null
                    ? Text(
                        '$stepIndex',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 10, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackCategoryIcon(String category, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          _getCategoryIcon(category),
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showReviewDialog(BuildContext context, AttractionModel att) {
    double selectedRating = 5.0;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dlgCtx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.rate_review_outlined, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Avaliar ${att.name}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Como foi sua experiência neste local?'),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      return IconButton(
                        icon: Icon(
                          star <= selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () => setDlgState(() => selectedRating = star.toDouble()),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: commentCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Escreva sua avaliação para outros viajantes...',
                      hintStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dlgCtx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await LocalDbService.instance.submitReview(
                      att.id,
                      selectedRating,
                      comment: commentCtrl.text.trim(),
                    );
                    await SocialService.instance.submitReview(
                      att.id,
                      selectedRating,
                      citySlug: att.cityId,
                    );
                    if (context.mounted) {
                      Navigator.pop(dlgCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.green,
                          content: Text('✓ Sua avaliação foi registrada e salva com sucesso!'),
                        ),
                      );
                    }
                  },
                  child: const Text('Publicar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(flavorConfigProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLiked = _selectedAttraction != null &&
        ref.watch(userLikesProvider).contains(_selectedAttraction!.id);

    final activePlanAsync = ref.watch(currentTripPlanProvider);
    final savedTripsAsync = ref.watch(savedTripsProvider);
    TripPlan? activePlan = activePlanAsync.value;
    if (activePlan == null && savedTripsAsync.value != null && savedTripsAsync.value!.isNotEmpty) {
      activePlan = savedTripsAsync.value!.first;
    }

    final isRoteiroMode = _selectedCityFilter == 'roteiro';

    final List<ItineraryStop> routeStops = isRoteiroMode && activePlan != null
        ? (_selectedDayFilter == null
            ? activePlan.days.expand((d) => d.stops).toList()
            : (activePlan.days.where((d) => d.dayNumber == _selectedDayFilter).isNotEmpty
                ? activePlan.days.firstWhere((d) => d.dayNumber == _selectedDayFilter).stops
                : activePlan.days.expand((d) => d.stops).toList()))
        : const [];

    final attractionsAsync = ref.watch(curatedAttractionsProvider);
    final allAttractions = attractionsAsync.value ?? MockPeData.topAttractions;

    List<AttractionModel> baseAttractions;
    if (_selectedCityFilter == 'near') {
      baseAttractions = List<AttractionModel>.from(allAttractions)
        ..sort((a, b) {
          final distA = TripOptimizerService.calculateDistanceMeters(
            _userLocation.latitude, _userLocation.longitude, a.lat, a.lon);
          final distB = TripOptimizerService.calculateDistanceMeters(
            _userLocation.latitude, _userLocation.longitude, b.lat, b.lon);
          return distA.compareTo(distB);
        });
    } else if (_selectedCityFilter == 'todos' || _selectedCityFilter == 'roteiro') {
      baseAttractions = allAttractions;
    } else {
      baseAttractions = allAttractions
          .where((a) => a.cityId.toLowerCase().contains(_selectedCityFilter))
          .toList();
    }

    final filteredAttractions = _searchQuery.isEmpty
        ? baseAttractions
        : allAttractions.where((a) =>
            a.name.toLowerCase().contains(_searchQuery) ||
            a.cityName.toLowerCase().contains(_searchQuery) ||
            a.category.toLowerCase().contains(_searchQuery) ||
            a.description.toLowerCase().contains(_searchQuery)).toList();

    // Se nenhum selecionado ou o atual não está na lista filtrada, seleciona o mais adequado
    final hasMatchInAttractions = _selectedAttraction != null && filteredAttractions.any((a) => a.id == _selectedAttraction!.id);
    final hasMatchInStops = _selectedAttraction != null && routeStops.any((s) => s.place.id == _selectedAttraction!.id);

    if ((_selectedAttraction == null || (isRoteiroMode ? !hasMatchInStops : !hasMatchInAttractions))) {
      if (isRoteiroMode && routeStops.isNotEmpty) {
        _selectedAttraction = routeStops.first.place.toAttractionModel();
      } else if (filteredAttractions.isNotEmpty) {
        // Seleciona a atração mais próxima do centro do polo atual
        final center = _cityCenters[_selectedCityFilter] ?? _cityCenters['recife']!;
        final sorted = List<AttractionModel>.from(filteredAttractions)
          ..sort((a, b) {
            final dA = TripOptimizerService.calculateDistanceMeters(center.latitude, center.longitude, a.lat, a.lon);
            final dB = TripOptimizerService.calculateDistanceMeters(center.latitude, center.longitude, b.lat, b.lon);
            return dA.compareTo(dB);
          });
        _selectedAttraction = sorted.first;
      }
    }

    final distanceMeters = _selectedAttraction != null
        ? TripOptimizerService.calculateDistanceMeters(
            _userLocation.latitude,
            _userLocation.longitude,
            _selectedAttraction!.lat,
            _selectedAttraction!.lon,
          )
        : null;

    final distanceLabel = distanceMeters != null
        ? (distanceMeters < 1000
            ? '${distanceMeters.round()} m'
            : '${(distanceMeters / 1000).toStringAsFixed(1)} km')
        : null;

    return Scaffold(
      body: Stack(
        children: [
          // 1. MAPA INTERATIVO REAL (OpenStreetMap / CartoDB via FlutterMap)
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(-8.0631, -34.8711),
              initialZoom: 12.0,
              minZoom: 4.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: isDark
                    ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.onetour.pe',
              ),

              // Rota Traçada Inteligente quando em modo Roteiro
              if (isRoteiroMode && routeStops.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routeStops.map((s) => LatLng(s.place.lat, s.place.lon)).toList(),
                      strokeWidth: 4.5,
                      color: config.primaryColor,
                    ),
                  ],
                ),

              // Marcadores do Mapa com Foto Miniatura + Posição do Usuário
              MarkerLayer(
                markers: [
                  // Marcador de posição do usuário ("Você está aqui")
                  Marker(
                    point: _userLocation,
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.withValues(alpha: 0.22),
                          ),
                        ),
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0F4C81),
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 1. Em modo Roteiro, renderiza outras atrações como fotos secundárias (para nada sumir no mapa!)
                  if (isRoteiroMode)
                    ...allAttractions
                        .where((att) => !routeStops.any((s) => s.place.id == att.id || s.place.name.toLowerCase() == att.name.toLowerCase()))
                        .map((att) {
                          final isSelected = _selectedAttraction?.id == att.id;
                          return Marker(
                            point: LatLng(att.lat, att.lon),
                            width: isSelected ? 62 : 46,
                            height: isSelected ? 70 : 54,
                            alignment: Alignment.bottomCenter,
                            child: _buildPhotoMarker(
                              name: att.name,
                              imageUrl: att.imageUrl,
                              category: att.category,
                              rating: att.rating,
                              isSelected: isSelected,
                              primaryColor: config.primaryColor,
                              secondaryColor: config.secondaryColor,
                              isDark: isDark,
                              onTap: () {
                                setState(() => _selectedAttraction = att);
                                _mapController.move(LatLng(att.lat, att.lon), 15.0);
                              },
                            ),
                          );
                        }),

                  // 2. Marcadores das paradas do Roteiro (com leque anti-sobreposição e números 1, 2, 3...)
                  if (isRoteiroMode)
                    ..._buildDispersedRouteMarkers(
                      routeStops: routeStops,
                      selectedAttractionId: _selectedAttraction?.id,
                      config: config,
                      isDark: isDark,
                    )
                  else
                    ...filteredAttractions.map((att) {
                      final isSelected = _selectedAttraction?.id == att.id;
                      return Marker(
                        point: LatLng(att.lat, att.lon),
                        width: isSelected ? 64 : 52,
                        height: isSelected ? 72 : 60,
                        alignment: Alignment.bottomCenter,
                        child: _buildPhotoMarker(
                          name: att.name,
                          imageUrl: att.imageUrl,
                          category: att.category,
                          rating: att.rating,
                          isSelected: isSelected,
                          primaryColor: config.primaryColor,
                          secondaryColor: config.secondaryColor,
                          isDark: isDark,
                          onTap: () {
                            setState(() => _selectedAttraction = att);
                            _mapController.move(LatLng(att.lat, att.lon), 14.5);
                          },
                        ),
                      );
                    }),
                ],
              ),
            ],
          ),

          // 2. HEADER SUPERIOR COM BUSCA REAL E FILTROS DE POLOS
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      if (Navigator.canPop(context))
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search, color: config.primaryColor),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: _performSearch,
                                  onSubmitted: _performSearch,
                                  textInputAction: TextInputAction.search,
                                  decoration: InputDecoration(
                                    hintText: 'Buscar local, praia ou atração...',
                                    hintStyle: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                              if (_searchQuery.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                                  onPressed: _clearSearch,
                                  tooltip: 'Limpar busca',
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade600,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.public, color: Colors.white, size: 10),
                                      SizedBox(width: 4),
                                      Text(
                                        'OSM LIVE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(Icons.my_location, color: config.primaryColor),
                          onPressed: () => _filterCity('near'),
                          tooltip: 'Perto de Você',
                        ),
                      ),
                    ],
                  ),
                ),

                // Barra 1: Chips Horizontais dos Polos Turísticos e Roteiro Ativo
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      if (activePlan != null)
                        _buildCityChip(
                          'roteiro',
                          '🗺️ Roteiro Ativo',
                          Icons.route,
                          config,
                          activePlan: activePlan,
                        ),
                      _buildCityChip('near', 'Perto de Você', Icons.near_me_rounded, config),
                      _buildCityChip('todos', 'Todos os Polos', Icons.travel_explore, config),
                      _buildCityChip('recife', 'Recife', Icons.location_city, config),
                      _buildCityChip('porto_de_galinhas', 'Porto de Galinhas', Icons.beach_access, config),
                      _buildCityChip('olinda', 'Olinda', Icons.account_balance, config),
                      _buildCityChip('carneiros', 'Carneiros', Icons.sailing, config),
                      _buildCityChip('noronha', 'Noronha', Icons.eco, config),
                    ],
                  ),
                ),

                // Barra 2: Sub-Barra de Dias do Roteiro (com alto contraste quando Roteiro está ativo)
                if (isRoteiroMode && activePlan != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildDayChip(null, '📅 Rota Completa (${activePlan.totalStopsCount})', config, activePlan: activePlan),
                          for (final d in activePlan.days)
                            _buildDayChip(d.dayNumber, '☀️ Dia ${d.dayNumber} (${d.stops.length})', config, activePlan: activePlan),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 3. BOTÕES DE CONTROLE DE ZOOM LATERAL
          Positioned(
            right: 16,
            top: 235,
            child: Column(
              children: [
                _buildMapControlBtn(
                  icon: Icons.add,
                  onTap: () {
                    final zoom = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, zoom + 1);
                  },
                ),
                const SizedBox(height: 8),
                _buildMapControlBtn(
                  icon: Icons.remove,
                  onTap: () {
                    final zoom = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, zoom - 1);
                  },
                ),
              ],
            ),
          ),

          // 4. CARD INFERIOR FLUTUANTE DA ATRAÇÃO SELECIONADA
          if (_selectedAttraction != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        _selectedAttraction!.imageUrl,
                        width: 85,
                        height: 85,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 85,
                          height: 85,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.photo, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isRoteiroMode ? '📍 Parada no Roteiro' : '#${_selectedAttraction!.rankPosition} no Estado',
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              if (distanceLabel != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: config.primaryColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.near_me_rounded, size: 10, color: config.primaryColor),
                                      const SizedBox(width: 3),
                                      Text(
                                        distanceLabel,
                                        style: TextStyle(
                                          color: config.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const Spacer(),
                              const Icon(Icons.star, size: 14, color: Colors.amber),
                              Text(
                                ' ${_selectedAttraction!.rating}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedAttraction!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            '${_selectedAttraction!.cityName} • ${distanceLabel != null ? "$distanceLabel • " : ""}${_selectedAttraction!.durationMinutes} min',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              SizedBox(
                                height: 32,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: config.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () {
                                    context.push('/cidade/${_selectedAttraction!.cityId}');
                                  },
                                  icon: const Icon(Icons.arrow_forward, size: 13),
                                  label: const Text('Guia', style: TextStyle(fontSize: 11)),
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: Icon(
                                  isLiked ? Icons.favorite : Icons.favorite_border,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                onPressed: () {
                                  ref.read(userLikesProvider.notifier).toggleLike(_selectedAttraction!.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isLiked
                                            ? 'Removido dos favoritos'
                                            : 'Salvo nos seus favoritos offline! (❤️)',
                                      ),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                                tooltip: 'Salvar',
                              ),
                              IconButton(
                                icon: const Icon(Icons.rate_review_outlined, color: Colors.amber, size: 20),
                                onPressed: () => _showReviewDialog(context, _selectedAttraction!),
                                tooltip: 'Avaliar',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDayChip(int? dayNumber, String title, dynamic config, {required TripPlan activePlan}) {
    final isSelected = _selectedCityFilter == 'roteiro' && _selectedDayFilter == dayNumber;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color textColor = isSelected
        ? Colors.white
        : (isDark ? Colors.white : const Color(0xFF0F172A));
    final Color bgColor = isSelected
        ? (dayNumber == null ? const Color(0xFF0F4C81) : const Color(0xFFEA580C))
        : (isDark ? const Color(0xFF1E293B) : Colors.white);
    final Color borderColor = isSelected
        ? Colors.white
        : (isDark ? const Color(0xFF64748B) : const Color(0xFF0F172A));
    final Color iconColor = isSelected
        ? Colors.white
        : (isDark ? Colors.amberAccent : const Color(0xFFEA580C));

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _filterRoteiroDay(dayNumber, activePlan),
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7.5),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor, width: isSelected ? 2.0 : 1.8),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? (dayNumber == null
                          ? const Color(0xFF0F4C81).withValues(alpha: 0.45)
                          : const Color(0xFFEA580C).withValues(alpha: 0.45))
                      : Colors.black.withValues(alpha: 0.22),
                  blurRadius: isSelected ? 8 : 4.5,
                  offset: const Offset(0, 2.5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  dayNumber == null ? Icons.calendar_month_rounded : Icons.schedule_rounded,
                  size: 14,
                  color: iconColor,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCityChip(String key, String title, IconData icon, dynamic config, {TripPlan? activePlan}) {
    final isSelected = _selectedCityFilter == key;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color textColor = isSelected
        ? Colors.white
        : (isDark ? Colors.white : const Color(0xFF0F172A));
    final Color iconColor = isSelected
        ? Colors.white
        : (isDark ? const Color(0xFF38BDF8) : config.primaryColor);
    final Color bgColor = isSelected
        ? config.primaryColor
        : (isDark ? const Color(0xFF1E293B) : Colors.white);
    final Color borderColor = isSelected
        ? Colors.white
        : (isDark ? const Color(0xFF64748B) : const Color(0xFF0F172A));

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _filterCity(key, activePlan: activePlan),
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor, width: isSelected ? 2.0 : 1.8),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? config.primaryColor.withValues(alpha: 0.45)
                      : Colors.black.withValues(alpha: 0.22),
                  blurRadius: isSelected ? 8 : 4.5,
                  offset: const Offset(0, 2.5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: iconColor),
                const SizedBox(width: 7),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapControlBtn({required IconData icon, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onTap,
      ),
    );
  }
}

