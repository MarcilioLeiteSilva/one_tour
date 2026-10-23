import 'package:flutter/material.dart';

enum AppFlavor {
  pe, sp, rj, ba, mg, ce, pr, sc, rs, al,
  pb, rn, se, ma, pi, es, go, df, mt, ms,
  am, pa, to, ro, ac, ap, rr;

  static AppFlavor fromString(String? value) {
    if (value == null) return AppFlavor.pe;
    return AppFlavor.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AppFlavor.pe,
    );
  }
}

class FlavorConfig {
  final AppFlavor flavor;
  final String uf;
  final String stateName;
  final String appName;
  final String slogan;
  final String capital;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final bool hasCoastline;
  final bool hasBoatTours;

  const FlavorConfig({
    required this.flavor,
    required this.uf,
    required this.stateName,
    required this.appName,
    required this.slogan,
    required this.capital,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    this.hasCoastline = false,
    this.hasBoatTours = false,
  });

  static FlavorConfig of(AppFlavor flavor) {
    switch (flavor) {
      case AppFlavor.pe:
        return const FlavorConfig(
          flavor: AppFlavor.pe,
          uf: 'PE',
          stateName: 'Pernambuco',
          appName: 'Tour Pernambuco',
          slogan: 'Cultura, frevo, mar e encantos do litoral ao sertão',
          capital: 'Recife',
          primaryColor: Color(0xFF0F4C81), // Azul clássico
          secondaryColor: Color(0xFFEAA221), // Dourado sol
          accentColor: Color(0xFFD62828), // Vermelho frevo
          hasCoastline: true,
          hasBoatTours: true,
        );
      case AppFlavor.sp:
        return const FlavorConfig(
          flavor: AppFlavor.sp,
          uf: 'SP',
          stateName: 'São Paulo',
          appName: 'Tour São Paulo',
          slogan: 'Metrópole vibrante, gastronomia e refúgios na serra e praia',
          capital: 'São Paulo',
          primaryColor: Color(0xFF1E293B),
          secondaryColor: Color(0xFFE11D48),
          accentColor: Color(0xFF0284C7),
          hasCoastline: true,
          hasBoatTours: true,
        );
      case AppFlavor.rj:
        return const FlavorConfig(
          flavor: AppFlavor.rj,
          uf: 'RJ',
          stateName: 'Rio de Janeiro',
          appName: 'Tour Rio de Janeiro',
          slogan: 'Cidade maravilhosa, praias icônicas e serra histórica',
          capital: 'Rio de Janeiro',
          primaryColor: Color(0xFF0369A1),
          secondaryColor: Color(0xFFF59E0B),
          accentColor: Color(0xFF10B981),
          hasCoastline: true,
          hasBoatTours: true,
        );
      case AppFlavor.ba:
        return const FlavorConfig(
          flavor: AppFlavor.ba,
          uf: 'BA',
          stateName: 'Bahia',
          appName: 'Tour Bahia',
          slogan: 'Axé, patrimônio histórico, culinária única e praias paradisíacas',
          capital: 'Salvador',
          primaryColor: Color(0xFF0284C7),
          secondaryColor: Color(0xFFF97316),
          accentColor: Color(0xFF16A34A),
          hasCoastline: true,
          hasBoatTours: true,
        );
      default:
        // Configuração genérica e flexível para os demais estados
        final ufUpper = flavor.name.toUpperCase();
        return FlavorConfig(
          flavor: flavor,
          uf: ufUpper,
          stateName: 'Estado $ufUpper',
          appName: 'Tour $ufUpper',
          slogan: 'Descubra os melhores roteiros e atrações',
          capital: 'Capital',
          primaryColor: const Color(0xFF0F4C81),
          secondaryColor: const Color(0xFFF59E0B),
          accentColor: const Color(0xFF10B981),
        );
    }
  }
}
