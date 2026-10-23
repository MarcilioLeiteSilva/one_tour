import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../domain/house_ad_model.dart';
import '../services/house_ads_service.dart';

class HouseAdTopCard extends ConsumerStatefulWidget {
  final HouseAdModel ad;

  const HouseAdTopCard({super.key, required this.ad});

  @override
  ConsumerState<HouseAdTopCard> createState() => _HouseAdTopCardState();
}

class _HouseAdTopCardState extends ConsumerState<HouseAdTopCard> {
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

    return InkWell(
      onTap: _handleTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.amber.withValues(alpha: 0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.ad.imageUrl,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 72,
                  height: 72,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.star, color: Colors.amber),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.ad.tag,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.ad.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.ad.subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: config.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: config.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
