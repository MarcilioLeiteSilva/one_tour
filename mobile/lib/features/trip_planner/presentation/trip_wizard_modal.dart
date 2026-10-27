import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/ads/admob_service.dart';
import '../../../core/config/app_config.dart';
import '../../../l10n/app_localizations.dart';
import '../../explore/presentation/explore_controller.dart';
import '../domain/trip_request.dart';
import 'trip_planner_controller.dart';

class TripWizardModal extends ConsumerStatefulWidget {
  final String cityName;

  const TripWizardModal({super.key, required this.cityName});

  @override
  ConsumerState<TripWizardModal> createState() => _TripWizardModalState();
}

class _TripWizardModalState extends ConsumerState<TripWizardModal> {
  late String _selectedCity;
  int _selectedDays = 3;
  int _selectedPace = 1; // 0: Tranquilo, 1: Moderado, 2: Intenso
  int _selectedCompanion = 1; // 0: Solo, 1: Casal, 2: Família, 3: Amigos

  final Set<String> _selectedInterests = {'praias', 'cultura', 'gastronomia'};

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.cityName;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final config = ref.watch(flavorConfigProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final citiesAsync = ref.watch(citiesProvider);
    final citiesList = citiesAsync.value?.map((c) => c.name).toList() ?? [config.capital];
    if (_selectedCity.isEmpty || (!citiesList.any((c) => c.toLowerCase() == _selectedCity.toLowerCase()) && widget.cityName.isEmpty)) {
      _selectedCity = citiesList.first;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barra de arrasto
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Título do Assistente
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.orange, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.tripPlannerTitle,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Roteiro inteligente para $_selectedCity',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Pergunta 0: Destino Polo
            Text('Escolha o Destino', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: citiesList.map((city) {
                  return _buildCityChip(city, Icons.location_on_rounded, config);
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Pergunta 1: Quantos dias?
            Text(l10n.howManyDays, style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                final day = index + 1;
                final isSelected = _selectedDays == day;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDays = day),
                  child: Container(
                    width: 55,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? config.primaryColor : (isDark ? const Color(0xFF1E293B) : Colors.white),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isSelected ? 0.2 : 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white : const Color(0xFF0F172A)),
                          ),
                        ),
                        Text(
                          day == 1 ? 'dia' : 'dias',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white.withOpacity(0.9)
                                : (isDark ? Colors.grey.shade400 : const Color(0xFF475569)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 20),

            // Pergunta 2: Ritmo de viagem
            Text(l10n.whatPace, style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            _PaceOption(
              title: l10n.paceRelaxed,
              isSelected: _selectedPace == 0,
              onTap: () => setState(() => _selectedPace = 0),
              activeColor: config.primaryColor,
            ),
            const SizedBox(height: 8),
            _PaceOption(
              title: l10n.paceModerate,
              isSelected: _selectedPace == 1,
              onTap: () => setState(() => _selectedPace = 1),
              activeColor: config.primaryColor,
            ),
            const SizedBox(height: 8),
            _PaceOption(
              title: l10n.paceIntense,
              isSelected: _selectedPace == 2,
              onTap: () => setState(() => _selectedPace = 2),
              activeColor: config.primaryColor,
            ),

            const SizedBox(height: 20),

            // Pergunta 3: Com quem viaja?
            Text(l10n.whoTravels, style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChipButton(
                  label: l10n.travelerSolo,
                  isSelected: _selectedCompanion == 0,
                  onTap: () => setState(() => _selectedCompanion = 0),
                  activeColor: config.primaryColor,
                ),
                _FilterChipButton(
                  label: l10n.travelerCouple,
                  isSelected: _selectedCompanion == 1,
                  onTap: () => setState(() => _selectedCompanion = 1),
                  activeColor: config.primaryColor,
                ),
                _FilterChipButton(
                  label: l10n.travelerFamily,
                  isSelected: _selectedCompanion == 2,
                  onTap: () => setState(() => _selectedCompanion = 2),
                  activeColor: config.primaryColor,
                ),
                _FilterChipButton(
                  label: l10n.travelerFriends,
                  isSelected: _selectedCompanion == 3,
                  onTap: () => setState(() => _selectedCompanion = 3),
                  activeColor: config.primaryColor,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Pergunta 4: Interesses
            Text(l10n.interestsTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChipButton(
                  label: l10n.interestBeach,
                  isSelected: _selectedInterests.contains('praias'),
                  onTap: () {
                    setState(() {
                      if (_selectedInterests.contains('praias')) {
                        _selectedInterests.remove('praias');
                      } else {
                        _selectedInterests.add('praias');
                      }
                    });
                  },
                  activeColor: config.primaryColor,
                ),
                _FilterChipButton(
                  label: l10n.interestCulture,
                  isSelected: _selectedInterests.contains('cultura'),
                  onTap: () {
                    setState(() {
                      if (_selectedInterests.contains('cultura')) {
                        _selectedInterests.remove('cultura');
                      } else {
                        _selectedInterests.add('cultura');
                      }
                    });
                  },
                  activeColor: config.primaryColor,
                ),
                _FilterChipButton(
                  label: l10n.interestGastronomy,
                  isSelected: _selectedInterests.contains('gastronomia'),
                  onTap: () {
                    setState(() {
                      if (_selectedInterests.contains('gastronomia')) {
                        _selectedInterests.remove('gastronomia');
                      } else {
                        _selectedInterests.add('gastronomia');
                      }
                    });
                  },
                  activeColor: config.primaryColor,
                ),
                _FilterChipButton(
                  label: l10n.interestNature,
                  isSelected: _selectedInterests.contains('natureza'),
                  onTap: () {
                    setState(() {
                      if (_selectedInterests.contains('natureza')) {
                        _selectedInterests.remove('natureza');
                      } else {
                        _selectedInterests.add('natureza');
                      }
                    });
                  },
                  activeColor: config.primaryColor,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Botão Gerar Roteiro
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: config.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.bolt_rounded, color: Colors.amber),
                label: Text(
                  l10n.btnGenerateTrip,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onPressed: () async {
                  final pace = _selectedPace == 0
                      ? TripPace.relaxed
                      : (_selectedPace == 1 ? TripPace.moderate : TripPace.intense);
                  final companion = _selectedCompanion == 0
                      ? TripCompanion.solo
                      : (_selectedCompanion == 1
                          ? TripCompanion.couple
                          : (_selectedCompanion == 2
                              ? TripCompanion.family
                              : TripCompanion.friends));

                  final request = TripRequest(
                    cityName: _selectedCity,
                    days: _selectedDays,
                    pace: pace,
                    companion: companion,
                    interests: Set.from(_selectedInterests),
                  );

                  Navigator.pop(context);
                  final plan = await ref.read(currentTripPlanProvider.notifier).generateTrip(request);
                  if (context.mounted && plan != null) {
                    ref.read(adMobServiceProvider).showInterstitial(
                          uf: config.uf,
                          onDismissed: () {
                            if (context.mounted) {
                              context.push('/roteiro/${plan.id}');
                            }
                          },
                        );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCityChip(String city, IconData icon, dynamic config) {
    final isSelected = _selectedCity.toLowerCase().trim() == city.toLowerCase().trim();
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
        ? Colors.transparent
        : (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8));

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedCity = city),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isSelected ? 0.2 : 0.06),
                  blurRadius: isSelected ? 6 : 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: iconColor),
                const SizedBox(width: 6),
                Text(
                  city,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaceOption extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;

  const _PaceOption({
    required this.title,
    required this.isSelected,
    required this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(0.12)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
            width: isSelected ? 1.8 : 1.3,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w700,
                color: isSelected
                    ? activeColor
                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: activeColor, size: 18)
            else
              Icon(Icons.circle_outlined,
                  color: isDark ? Colors.grey.shade400 : const Color(0xFF94A3B8), size: 18),
          ],
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;

  const _FilterChipButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color textColor = isSelected
        ? Colors.white
        : (isDark ? Colors.white : const Color(0xFF0F172A));
    final Color bgColor = isSelected
        ? activeColor
        : (isDark ? const Color(0xFF1E293B) : Colors.white);
    final Color borderColor = isSelected
        ? Colors.transparent
        : (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.2 : 0.06),
              blurRadius: isSelected ? 6 : 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
