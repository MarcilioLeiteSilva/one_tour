import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../explore/data/mock_pe_data.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  AttractionModel? _selectedAttraction = MockPeData.topAttractions.first;

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(flavorConfigProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Área do Mapa Vetorial Offline (MapLibre GL Container)
          Container(
            color: isDark ? const Color(0xFF0B132B) : const Color(0xFFE2E8F0),
            child: Stack(
              children: [
                // Textura visual simulando mapa estilizado de Pernambuco
                CustomPaint(
                  size: Size.infinite,
                  painter: _MapGridPainter(isDark: isDark),
                ),
                // Pins Interativos sobre o mapa
                Positioned(
                  top: 220,
                  left: 120,
                  child: _MapPin(
                    title: 'Marco Zero',
                    categoryIcon: Icons.account_balance,
                    isSelected: _selectedAttraction?.id == 'marco_zero',
                    onTap: () => setState(() => _selectedAttraction = MockPeData.topAttractions[0]),
                  ),
                ),
                Positioned(
                  top: 140,
                  left: 200,
                  child: _MapPin(
                    title: 'Alto da Sé',
                    categoryIcon: Icons.church,
                    isSelected: _selectedAttraction?.id == 'alto_da_se',
                    onTap: () => setState(() => _selectedAttraction = MockPeData.topAttractions[2]),
                  ),
                ),
                Positioned(
                  top: 360,
                  left: 180,
                  child: _MapPin(
                    title: 'Porto de Galinhas',
                    categoryIcon: Icons.beach_access,
                    isSelected: _selectedAttraction?.id == 'piscinas_porto',
                    onTap: () => setState(() => _selectedAttraction = MockPeData.topAttractions[1]),
                  ),
                ),
              ],
            ),
          ),

          // Header Superior Flutuante
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: config.primaryColor),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Buscar no mapa offline...',
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'OFFLINE',
                              style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
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
                        BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.my_location),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Card Flutuante Inferior com Detalhes da Atração Selecionada
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
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 16,
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
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
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
                                  color: Colors.amber.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '#${_selectedAttraction!.rankPosition} no Estado',
                                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 10),
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.star, size: 13, color: Colors.amber),
                              Text(' ${_selectedAttraction!.rating}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedAttraction!.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            '${_selectedAttraction!.cityName} • ${_selectedAttraction!.durationMinutes} min',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 32,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: config.primaryColor,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.directions, size: 14),
                              label: const Text('Como Chegar', style: TextStyle(fontSize: 11)),
                              onPressed: () {},
                            ),
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
}

class _MapPin extends StatelessWidget {
  final String title;
  final IconData categoryIcon;
  final bool isSelected;
  final VoidCallback onTap;

  const _MapPin({
    required this.title,
    required this.categoryIcon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.redAccent : const Color(0xFF0F4C81),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(categoryIcon, color: Colors.white, size: 18),
          ),
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  final bool isDark;

  _MapGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)
      ..strokeWidth = 1.0;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
