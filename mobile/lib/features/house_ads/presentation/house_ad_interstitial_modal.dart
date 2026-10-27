import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../domain/house_ad_model.dart';
import '../services/house_ads_service.dart';
import 'house_ad_image.dart';

class HouseAdInterstitialModal extends ConsumerStatefulWidget {
  final HouseAdModel ad;

  const HouseAdInterstitialModal({super.key, required this.ad});

  static Future<void> show(BuildContext context, HouseAdModel ad) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => HouseAdInterstitialModal(ad: ad),
    );
  }

  @override
  ConsumerState<HouseAdInterstitialModal> createState() =>
      _HouseAdInterstitialModalState();
}

class _HouseAdInterstitialModalState
    extends ConsumerState<HouseAdInterstitialModal> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(houseAdsServiceProvider).trackImpression(widget.ad);
    });
  }

  void _handleAction() {
    ref.read(houseAdsServiceProvider).trackClick(widget.ad);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Abrindo: ${widget.ad.title} (${widget.ad.targetUrl})'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(flavorConfigProvider);
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Image com botão de fechar
          Stack(
            children: [
              HouseAdImage(
                imageUrl: widget.ad.imageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.ad.tag,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Texto e Chamada
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  widget.ad.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.ad.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: config.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _handleAction,
                    child: Text(
                      widget.ad.actionLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Continuar para o Roteiro', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
