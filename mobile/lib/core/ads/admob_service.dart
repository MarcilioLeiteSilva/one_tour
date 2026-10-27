import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'admob_config.dart';

final adMobServiceProvider = Provider<AdMobService>((ref) {
  return AdMobService.instance;
});

class AdMobService {
  static final AdMobService instance = AdMobService._internal();
  AdMobService._internal();

  bool _initialized = false;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  DateTime? _lastInterstitialShownAt;

  // Intervalo mínimo de 3 minutos entre intersticiais para respeitar a política de UX
  static const Duration _minInterstitialInterval = Duration(minutes: 3);

  /// Inicializa o SDK de anúncios em background de forma segura
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      debugPrint('🚀 [AdMobService] SDK do Google Mobile Ads inicializado com sucesso.');
    } catch (e) {
      debugPrint('⚠️ [AdMobService] Erro ao inicializar MobileAds: $e');
    }
  }

  /// Pré-carrega um Intersticial para a UF especificada
  void preloadInterstitial(String uf) {
    if (!_initialized || _isInterstitialLoading || _interstitialAd != null) {
      return;
    }

    _isInterstitialLoading = true;
    final units = AdMobConfig.getUnitsForUf(uf);

    InterstitialAd.load(
      adUnitId: units.interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          debugPrint('✅ [AdMobService] Interstitial pré-carregado com sucesso para $uf');
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isInterstitialLoading = false;
          debugPrint('⚠️ [AdMobService] Falha ao carregar Interstitial ($uf): ${error.message}');
        },
      ),
    );
  }

  /// Exibe o Intersticial se respeitar o limite de frequência.
  /// Caso não haja anúncio ou o tempo mínimo não tenha passado, executa [onDismissed] imediatamente.
  void showInterstitial({
    required String uf,
    VoidCallback? onDismissed,
  }) {
    // 1. Verifica tempo mínimo desde a última exibição (Frequency Capping)
    if (_lastInterstitialShownAt != null) {
      final elapsed = DateTime.now().difference(_lastInterstitialShownAt!);
      if (elapsed < _minInterstitialInterval) {
        debugPrint(
            '⏳ [AdMobService] Interstitial suprimido por frequency cap (${elapsed.inSeconds}s < ${_minInterstitialInterval.inSeconds}s)');
        onDismissed?.call();
        return;
      }
    }

    // 2. Se temos anúncio pronto, exibe
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          _lastInterstitialShownAt = DateTime.now();
          onDismissed?.call();
          // Pré-carrega o próximo em background
          preloadInterstitial(uf);
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          debugPrint('⚠️ [AdMobService] Falha ao exibir Interstitial: ${error.message}');
          onDismissed?.call();
          preloadInterstitial(uf);
        },
      );

      _interstitialAd!.show();
      return;
    }

    // 3. Fallback: Se não estava pré-carregado, dispara o callback e tenta carregar para a próxima vez
    debugPrint('ℹ️ [AdMobService] Nenhum Interstitial pronto no momento. Prosseguindo.');
    onDismissed?.call();
    preloadInterstitial(uf);
  }

  /// Carrega e exibe um Vídeo Recompensado (Rewarded Ad)
  /// Usado para desbloqueio voluntário de download offline ou roteiros longos
  Future<void> showRewarded({
    required String uf,
    required void Function(RewardItem reward) onRewarded,
    VoidCallback? onFailed,
  }) async {
    final units = AdMobConfig.getUnitsForUf(uf);
    final completer = Completer<void>();
    bool rewardEarned = false;

    RewardedAd.load(
      adUnitId: units.rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!rewardEarned) {
                // Usuário fechou antes ou sem completar recompensa
                onFailed?.call();
              }
              if (!completer.isCompleted) completer.complete();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              debugPrint('⚠️ [AdMobService] Falha ao exibir Rewarded: ${error.message}');
              onFailed?.call();
              if (!completer.isCompleted) completer.complete();
            },
          );

          ad.show(
            onUserEarnedReward: (adWithoutView, reward) {
              rewardEarned = true;
              debugPrint('🎁 [AdMobService] Recompensa obtida: ${reward.amount} ${reward.type}');
              onRewarded(reward);
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('⚠️ [AdMobService] Falha ao carregar Rewarded ($uf): ${error.message}');
          onFailed?.call();
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );

    return completer.future;
  }
}
