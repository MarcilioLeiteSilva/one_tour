import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../l10n/app_localizations.dart';

class TripWizardModal extends ConsumerStatefulWidget {
  final String cityName;

  const TripWizardModal({super.key, required this.cityName});

  @override
  ConsumerState<TripWizardModal> createState() => _TripWizardModalState();
}

class _TripWizardModalState extends ConsumerState<TripWizardModal> {
  int _selectedDays = 3;
  int _selectedPace = 1; // 0: Tranquilo, 1: Moderado, 2: Intenso
  int _selectedCompanion = 1; // 0: Solo, 1: Casal, 2: Família, 3: Amigos

  final Set<String> _selectedInterests = {'praias', 'cultura', 'gastronomia'};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final config = ref.watch(flavorConfigProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                        'Roteiro inteligente para ${widget.cityName}',
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
                      color: isSelected ? config.primaryColor : theme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : Colors.grey.withOpacity(0.25),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : null,
                          ),
                        ),
                        Text(
                          day == 1 ? 'dia' : 'dias',
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey.shade500,
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
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/roteiro/roteiro_demo');
                },
              ),
            ),
          ],
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.08) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.withOpacity(0.2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? activeColor : null,
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: activeColor, size: 18)
            else
              const Icon(Icons.circle_outlined, color: Colors.grey, size: 18),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : null,
          ),
        ),
      ),
    );
  }
}
