import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/app_config.dart';
import '../../features/house_ads/domain/house_ad_model.dart';
import '../../features/house_ads/presentation/house_ad_banner.dart';
import '../../features/house_ads/services/house_ads_service.dart';
import 'admob_config.dart';

/// Banner Híbrido Inteligente (AdMob com Fallback Automático para House Ads)
/// 1. Tenta carregar banner do Google AdMob.
/// 2. Se estiver offline ou o AdMob falhar (sem preenchimento / no fill), exibe o House Ad local.
/// 3. Zero tela em branco, zero layout quebrado.
class HybridAdBanner extends ConsumerStatefulWidget {
  final String position;

  const HybridAdBanner({
    super.key,
    this.position = 'attraction_banner',
  });

  @override
  ConsumerState<HybridAdBanner> createState() => _HybridAdBannerState();
}

class _HybridAdBannerState extends ConsumerState<HybridAdBanner> {
  BannerAd? _bannerAd;
  bool _isAdMobLoaded = false;
  bool _adMobFailed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAdMobBanner();
  }

  void _loadAdMobBanner() {
    if (_bannerAd != null || _isAdMobLoaded) return;

    final config = ref.read(flavorConfigProvider);
    final units = AdMobConfig.getUnitsForUf(config.uf);

    _bannerAd = BannerAd(
      adUnitId: units.bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _isAdMobLoaded = true;
            _adMobFailed = false;
          });
          debugPrint('✅ [HybridAdBanner] AdMob Banner carregado com sucesso (${config.uf})');
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _bannerAd = null;
            _isAdMobLoaded = false;
            _adMobFailed = true;
          });
          debugPrint('ℹ️ [HybridAdBanner] AdMob falhou (${error.message}). Usando fallback House Ads.');
        },
      ),
    );

    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(flavorConfigProvider);

    // Se o AdMob carregou com sucesso, exibe o banner oficial do AdMob
    if (_isAdMobLoaded && _bannerAd != null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AdWidget(ad: _bannerAd!),
        ),
      );
    }

    // Fallback: Exibe anúncio da rede House Ads (Campanhas locais ou promoção cruzada)
    return Consumer(
      builder: (context, ref, _) {
        final adsAsync = ref.watch(
          houseAdsByPositionProvider(
            HouseAdQuery(
              uf: config.uf.toUpperCase(),
              position: widget.position,
            ),
          ),
        );

        return adsAsync.when(
          data: (ads) => ads.isNotEmpty
              ? HouseAdBanner(ad: ads.first)
              : const SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }
}
