import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../explore/data/mock_pe_data.dart';
import '../../explore/presentation/explore_controller.dart';
import '../../trip_planner/domain/itinerary_models.dart';
import '../../trip_planner/presentation/trip_planner_controller.dart';
import '../../trip_planner/services/local_db_service.dart';
import '../../social/services/social_service.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  AttractionModel? _selectedAttraction;
  String _selectedCityFilter = 'todos';
  String _searchQuery = '';

  // Coordenadas centrais das cidades polo de Pernambuco
  static const Map<String, LatLng> _cityCenters = {
    'todos': LatLng(-8.0631, -34.8711),
    'recife': LatLng(-8.0631, -34.8711),
    'porto_de_galinhas': LatLng(-8.5042, -35.0028),
    'olinda': LatLng(-8.0139, -34.8519),
    'carneiros': LatLng(-8.7042, -35.0883),
    'noronha': LatLng(-3.8549, -32.4297),
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCity(String cityKey, {TripPlan? activePlan}) {
    setState(() {
      _selectedCityFilter = cityKey;
      _searchQuery = '';
      _searchController.clear();
    });

    if (cityKey == 'roteiro' && activePlan != null && activePlan.days.isNotEmpty) {
      final firstStop = activePlan.days.first.stops.firstOrNull;
      if (firstStop != null) {
        _mapController.move(LatLng(firstStop.place.lat, firstStop.place.lon), 13.5);
        setState(() {
          _selectedAttraction = firstStop.place.toAttractionModel();
        });
        return;
      }
    }

    final target = _cityCenters[cityKey] ?? _cityCenters['todos']!;
    final zoom = cityKey == 'noronha' ? 12.5 : (cityKey == 'todos' ? 11.0 : 14.0);
    _mapController.move(target, zoom);
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

    final activePlan = ref.watch(currentTripPlanProvider).value;
    final isRoteiroMode = _selectedCityFilter == 'roteiro' && activePlan != null;

    final List<ItineraryStop> routeStops = isRoteiroMode
        ? activePlan.days.expand((d) => d.stops).toList()
        : const [];

    final attractionsAsync = ref.watch(curatedAttractionsProvider);
    final allAttractions = attractionsAsync.value ?? MockPeData.topAttractions;

    final visibleAttractions = _selectedCityFilter == 'todos' || isRoteiroMode
        ? allAttractions
        : allAttractions.where((a) => a.cityId.toLowerCase().contains(_selectedCityFilter)).toList();

    final filteredAttractions = _searchQuery.isEmpty
        ? visibleAttractions
        : visibleAttractions.where((a) =>
            a.name.toLowerCase().contains(_searchQuery) ||
            a.cityName.toLowerCase().contains(_searchQuery) ||
            a.category.toLowerCase().contains(_searchQuery)).toList();

    // Se nenhum selecionado, seleciona o primeiro visível
    if (_selectedAttraction == null && filteredAttractions.isNotEmpty) {
      _selectedAttraction = filteredAttractions.first;
    }

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

              // Marcadores do Mapa
              MarkerLayer(
                markers: isRoteiroMode
                    ? routeStops.asMap().entries.map((entry) {
                        final idx = entry.key + 1;
                        final stop = entry.value;
                        final isSelected = _selectedAttraction?.id == stop.place.id;

                        return Marker(
                          point: LatLng(stop.place.lat, stop.place.lon),
                          width: isSelected ? 48 : 38,
                          height: isSelected ? 48 : 38,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedAttraction = stop.place.toAttractionModel();
                              });
                              _mapController.move(LatLng(stop.place.lat, stop.place.lon), 15.0);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.orange : config.primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '$idx',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList()
                    : filteredAttractions.map((att) {
                        final isSelected = _selectedAttraction?.id == att.id;

                        return Marker(
                          point: LatLng(att.lat, att.lon),
                          width: isSelected ? 48 : 38,
                          height: isSelected ? 48 : 38,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedAttraction = att);
                              _mapController.move(LatLng(att.lat, att.lon), 14.5);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? config.primaryColor
                                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.white : config.primaryColor,
                                  width: isSelected ? 2.5 : 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _getCategoryIcon(att.category),
                                size: isSelected ? 22 : 18,
                                color: isSelected ? Colors.white : config.primaryColor,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
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
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                                  onChanged: (val) {
                                    setState(() => _searchQuery = val.toLowerCase().trim());
                                  },
                                  decoration: const InputDecoration(
                                    hintText: 'Buscar no mapa (ex: praia, marco)...',
                                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                              if (_searchQuery.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
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
                          onPressed: () => _filterCity('recife'),
                          tooltip: 'Recentrar no Marco Zero',
                        ),
                      ),
                    ],
                  ),
                ),

                // Barra de Chips Horizontais dos Polos Turísticos e Roteiro Ativo
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      if (activePlan != null)
                        _buildCityChip('roteiro', '📍 ${activePlan.title}', Icons.route, config, activePlan: activePlan),
                      _buildCityChip('todos', 'Todos os Polos', Icons.travel_explore, config),
                      _buildCityChip('recife', 'Recife', Icons.location_city, config),
                      _buildCityChip('porto_de_galinhas', 'Porto de Galinhas', Icons.beach_access, config),
                      _buildCityChip('olinda', 'Olinda', Icons.account_balance, config),
                      _buildCityChip('carneiros', 'Carneiros', Icons.sailing, config),
                      _buildCityChip('noronha', 'Noronha', Icons.eco, config),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. BOTÕES DE CONTROLE DE ZOOM LATERAL
          Positioned(
            right: 16,
            top: 140,
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
                                  '#${_selectedAttraction!.rankPosition} no Estado',
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
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
                            '${_selectedAttraction!.cityName} • ${_selectedAttraction!.durationMinutes} min',
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

  Widget _buildCityChip(String key, String title, IconData icon, dynamic config, {TripPlan? activePlan}) {
    final isSelected = _selectedCityFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        avatar: Icon(icon, size: 14, color: isSelected ? Colors.white : config.primaryColor),
        label: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : null,
          ),
        ),
        selectedColor: config.primaryColor,
        backgroundColor: Theme.of(context).cardColor,
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        onSelected: (_) => _filterCity(key, activePlan: activePlan),
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
