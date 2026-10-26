import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/app_flavor.dart';
import '../domain/network_state_model.dart';

/// Serviço que gerencia o status dos aplicativos da Rede One Tour.
/// Permite que os estados sejam ativados remotamente assim que forem lançados na Play Store,
/// sem necessidade de atualizar o app no dispositivo do usuário.
class NetworkStatusService {
  static final NetworkStatusService instance = NetworkStatusService._internal();
  NetworkStatusService._internal();

  // Endpoint remoto que fornece o status em tempo real da Rede One Tour
  static const String _remoteStatusUrl =
      'https://raw.githubusercontent.com/MarcilioLeiteSilva/one_tour/main/network_status.json';

  final Set<String> _localNotifiedStates = {};

  /// Lista padrão dos 27 estados da federação.
  /// Inicialmente, PE é o atual, AL e PB estão disponíveis para download,
  /// e os demais estão em preparação com opção de pré-cadastro.
  List<NetworkStateInfo> getInitialStates(AppFlavor currentFlavor) {
    final currentUf = FlavorConfig.of(currentFlavor).uf.toUpperCase();

    // Estados com lançamento prioritário na Rede One Tour
    final launchedUfs = {'PE', 'AL'};

    return AppFlavor.values.map((flavor) {
      final uf = FlavorConfig.of(flavor).uf.toUpperCase();
      NetworkAppStatus status;

      if (uf == currentUf) {
        status = NetworkAppStatus.current;
      } else if (launchedUfs.contains(uf)) {
        status = NetworkAppStatus.available;
      } else {
        status = NetworkAppStatus.comingSoon;
      }

      return NetworkStateInfo.fromFlavor(
        flavor,
        status: status,
        isNotified: _localNotifiedStates.contains(uf),
      );
    }).toList();
  }

  /// Carrega os status mais recentes da nuvem e mescla com os dados locais
  Future<List<NetworkStateInfo>> fetchRemoteStatus(AppFlavor currentFlavor) async {
    final baseStates = getInitialStates(currentFlavor);
    final currentUf = FlavorConfig.of(currentFlavor).uf.toUpperCase();

    try {
      final response = await http
          .get(Uri.parse(_remoteStatusUrl))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final Map<String, dynamic> rawData = jsonDecode(response.body);
        final Map<String, dynamic> statesMap = (rawData['states'] is Map<String, dynamic>)
            ? rawData['states'] as Map<String, dynamic>
            : rawData;

        final updated = baseStates.map((state) {
          final ufKey = state.uf.toLowerCase();
          if (statesMap.containsKey(ufKey)) {
            final remoteInfo = statesMap[ufKey];
            final statusStr = remoteInfo['status'] as String?;
            NetworkAppStatus newStatus = state.status;

            if (state.uf == currentUf) {
              newStatus = NetworkAppStatus.current;
            } else if (statusStr == 'active' || statusStr == 'available') {
              newStatus = NetworkAppStatus.available;
            } else if (statusStr == 'coming_soon') {
              newStatus = NetworkAppStatus.comingSoon;
            }

            return state.copyWith(
              status: newStatus,
              storeUrl: remoteInfo['storeUrl'] ?? state.storeUrl,
              isNotified: _localNotifiedStates.contains(state.uf),
            );
          }
          return state;
        }).toList();

        return updated;
      }
    } catch (e) {
      debugPrint('ℹ️ [NetworkStatusService] Usando status em cache local da rede: $e');
    }

    return baseStates;
  }

  /// Abre o app irmão se instalado ou direciona para a Google Play Store
  Future<bool> openOrInstallApp(NetworkStateInfo state) async {
    final packageName = state.packageName;

    // 1. Tenta abrir direto no app da Google Play Store (market://)
    final marketUri = Uri.parse('market://details?id=$packageName');
    // 2. Fallback para URL Web da Play Store
    final webUri = Uri.parse(
      state.storeUrl ?? 'https://play.google.com/store/apps/details?id=$packageName',
    );

    try {
      if (await canLaunchUrl(marketUri)) {
        return await launchUrl(marketUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUri)) {
        return await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('⚠️ Erro ao abrir aplicativo ou loja: $e');
    }
    return false;
  }

  /// Inscreve o usuário para receber notificação assim que o estado for lançado
  Future<bool> registerLaunchInterest(String uf) async {
    final cleanUf = uf.toUpperCase();
    _localNotifiedStates.add(cleanUf);

    try {
      // Inscreve no tópico FCM do estado correspondente
      final topic = 'launch_${cleanUf.toLowerCase()}';
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      debugPrint('🔔 [FCM] Inscrito no tópico de lançamento: $topic');
    } catch (e) {
      debugPrint('ℹ️ [FCM] Inscrição local registrada para $cleanUf');
    }

    return true;
  }
}

/// Provider Riverpod para os estados da Rede One Tour
final networkAppStatusProvider =
    StateNotifierProvider<NetworkStatusNotifier, List<NetworkStateInfo>>((ref) {
  final currentFlavor = ref.watch(appFlavorProvider);
  return NetworkStatusNotifier(currentFlavor);
});

class NetworkStatusNotifier extends StateNotifier<List<NetworkStateInfo>> {
  final AppFlavor currentFlavor;

  NetworkStatusNotifier(this.currentFlavor)
      : super(NetworkStatusService.instance.getInitialStates(currentFlavor)) {
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final updated = await NetworkStatusService.instance.fetchRemoteStatus(currentFlavor);
    state = updated;
  }

  Future<void> refresh() async {
    final updated = await NetworkStatusService.instance.fetchRemoteStatus(currentFlavor);
    state = updated;
  }

  Future<bool> openOrInstall(NetworkStateInfo stateInfo) async {
    return await NetworkStatusService.instance.openOrInstallApp(stateInfo);
  }

  Future<void> registerInterest(String uf) async {
    await NetworkStatusService.instance.registerLaunchInterest(uf);
    state = state.map((s) {
      if (s.uf == uf) {
        return s.copyWith(isNotified: true);
      }
      return s;
    }).toList();
  }
}
