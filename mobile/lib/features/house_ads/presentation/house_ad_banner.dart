import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../domain/house_ad_model.dart';
import '../services/house_ads_service.dart';

class HouseAdBanner extends ConsumerStatefulWidget {
  final HouseAdModel ad;

  const HouseAdBanner({super.key, required this.ad});

  @override
  ConsumerState<HouseAdBanner> createState() => _HouseAdBannerState();
}

class _HouseAdBannerState extends ConsumerState<HouseAdBanner> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(houseAdsServiceProvider).trackImpression(widget.ad);
    });
  }

  void _handleTap() {
    ref.read(houseAdsServiceProvider).trackClick(widget.ad);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Abrindo: ${widget.ad.title} (${widget.ad.targetUrl})'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(flavorConfigProvider);
    final theme = Theme.of(context);
    final isCrossPromo = widget.ad.type == 'cross_promotion';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCrossPromo
              ? config.primaryColor.withValues(alpha: 0.25)
              : Colors.amber.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagem de Capa com Tag Patrocinada
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                child: Image.network(
                  widget.ad.imageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 120,
                    color: Colors.grey.shade300,
                    child: const Center(child: Icon(Icons.campaign, size: 36, color: Colors.grey)),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCrossPromo ? config.primaryColor : Colors.amber.shade800,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCrossPromo ? Icons.travel_explore : Icons.verified,
                        color: Colors.white,
                        size: 11,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.ad.tag,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Conteúdo do Anúncio
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.ad.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.ad.subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCrossPromo ? config.primaryColor : Colors.amber.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: _handleTap,
                    child: Text(
                      widget.ad.actionLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
