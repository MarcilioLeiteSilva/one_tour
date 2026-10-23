class HouseAdModel {
  final String id;
  final String type; // 'direct_sponsor' | 'cross_promotion'
  final String title;
  final String subtitle;
  final String tag;
  final String imageUrl;
  final String actionLabel;
  final String targetUrl;
  final String targetUf;
  final String position; // 'home_card' | 'attraction_banner' | 'interstitial'

  const HouseAdModel({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.imageUrl,
    required this.actionLabel,
    required this.targetUrl,
    required this.targetUf,
    required this.position,
  });

  factory HouseAdModel.fromMap(Map<String, dynamic> map) {
    return HouseAdModel(
      id: map['id'] as String? ?? 'ad_default',
      type: map['type'] as String? ?? 'cross_promotion',
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
      tag: map['tag'] as String? ?? 'RECOMENDADO',
      imageUrl: map['imageUrl'] as String? ?? '',
      actionLabel: map['actionLabel'] as String? ?? 'Saiba Mais',
      targetUrl: map['targetUrl'] as String? ?? '',
      targetUf: map['targetUf'] as String? ?? 'PE',
      position: map['position'] as String? ?? 'attraction_banner',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'subtitle': subtitle,
      'tag': tag,
      'imageUrl': imageUrl,
      'actionLabel': actionLabel,
      'targetUrl': targetUrl,
      'targetUf': targetUf,
      'position': position,
    };
  }
}
