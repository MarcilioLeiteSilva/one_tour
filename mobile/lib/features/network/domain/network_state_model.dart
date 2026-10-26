import '../../../core/config/app_flavor.dart';

enum NetworkAppStatus {
  current,    // App ativo em execução (Pernambuco)
  installed,  // App vizinho instalado no celular
  available,  // Lançado na Play Store para download
  comingSoon, // Em preparação (pré-lançamento)
}

class NetworkStateInfo {
  final String uf;
  final String name;
  final String capital;
  final String packageName;
  final NetworkAppStatus status;
  final String? storeUrl;
  final String description;
  final int attractionsCount;
  final bool isNotified;

  const NetworkStateInfo({
    required this.uf,
    required this.name,
    required this.capital,
    required this.packageName,
    required this.status,
    this.storeUrl,
    required this.description,
    this.attractionsCount = 0,
    this.isNotified = false,
  });

  NetworkStateInfo copyWith({
    NetworkAppStatus? status,
    String? storeUrl,
    bool? isNotified,
  }) {
    return NetworkStateInfo(
      uf: uf,
      name: name,
      capital: capital,
      packageName: packageName,
      status: status ?? this.status,
      storeUrl: storeUrl ?? this.storeUrl,
      description: description,
      attractionsCount: attractionsCount,
      isNotified: isNotified ?? this.isNotified,
    );
  }

  factory NetworkStateInfo.fromFlavor(AppFlavor flavor, {NetworkAppStatus? status, bool isNotified = false}) {
    final conf = FlavorConfig.of(flavor);
    return NetworkStateInfo(
      uf: conf.uf,
      name: conf.stateName,
      capital: conf.capital,
      packageName: 'com.onetour.${conf.uf.toLowerCase()}',
      status: status ?? NetworkAppStatus.comingSoon,
      storeUrl: 'https://play.google.com/store/apps/details?id=com.onetour.${conf.uf.toLowerCase()}',
      description: 'Guias e mapas offline para ${conf.stateName}',
      isNotified: isNotified,
    );
  }

  factory NetworkStateInfo.fromJson(Map<String, dynamic> json) {
    return NetworkStateInfo(
      uf: json['uf'] ?? '',
      name: json['name'] ?? '',
      capital: json['capital'] ?? '',
      packageName: json['packageName'] ?? 'com.onetour.${(json['uf'] ?? '').toString().toLowerCase()}',
      status: _parseStatus(json['status']),
      storeUrl: json['storeUrl'],
      description: json['description'] ?? '',
      attractionsCount: json['attractionsCount'] ?? 0,
      isNotified: json['isNotified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uf': uf,
      'name': name,
      'capital': capital,
      'packageName': packageName,
      'status': status.name,
      'storeUrl': storeUrl,
      'description': description,
      'attractionsCount': attractionsCount,
      'isNotified': isNotified,
    };
  }

  static NetworkAppStatus _parseStatus(dynamic val) {
    if (val == 'current') return NetworkAppStatus.current;
    if (val == 'installed') return NetworkAppStatus.installed;
    if (val == 'available') return NetworkAppStatus.available;
    return NetworkAppStatus.comingSoon;
  }
}
