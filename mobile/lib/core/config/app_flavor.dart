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
      // 1. Pernambuco
      case AppFlavor.pe:
        return const FlavorConfig(
          flavor: AppFlavor.pe,
          uf: 'PE',
          stateName: 'Pernambuco',
          appName: 'Tour Pernambuco',
          slogan: 'Cultura, frevo, mar e encantos do litoral ao sertão',
          capital: 'Recife',
          primaryColor: Color(0xFF0F4C81),
          secondaryColor: Color(0xFFEAA221),
          accentColor: Color(0xFFD62828),
          hasCoastline: true,
          hasBoatTours: true,
        );

      // 2. São Paulo
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

      // 3. Rio de Janeiro
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

      // 4. Bahia
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

      // 5. Minas Gerais
      case AppFlavor.mg:
        return const FlavorConfig(
          flavor: AppFlavor.mg,
          uf: 'MG',
          stateName: 'Minas Gerais',
          appName: 'Tour Minas Gerais',
          slogan: 'Cidades históricas coloniais, queijo, café e hospitalidade',
          capital: 'Belo Horizonte',
          primaryColor: Color(0xFF78350F),
          secondaryColor: Color(0xFFD97706),
          accentColor: Color(0xFF059669),
          hasCoastline: false,
          hasBoatTours: true,
        );

      // 6. Ceará
      case AppFlavor.ce:
        return const FlavorConfig(
          flavor: AppFlavor.ce,
          uf: 'CE',
          stateName: 'Ceará',
          appName: 'Tour Ceará',
          slogan: 'Jericoacoara, falésias coloridas, dunas e sol o ano inteiro',
          capital: 'Fortaleza',
          primaryColor: Color(0xFF0284C7),
          secondaryColor: Color(0xFFF59E0B),
          accentColor: Color(0xFFEF4444),
          hasCoastline: true,
          hasBoatTours: true,
        );

      // 7. Paraná
      case AppFlavor.pr:
        return const FlavorConfig(
          flavor: AppFlavor.pr,
          uf: 'PR',
          stateName: 'Paraná',
          appName: 'Tour Paraná',
          slogan: 'Cataratas do Iguaçu, parques verdes e a serra paranaense',
          capital: 'Curitiba',
          primaryColor: Color(0xFF065F46),
          secondaryColor: Color(0xFF10B981),
          accentColor: Color(0xFFF59E0B),
          hasCoastline: true,
          hasBoatTours: true,
        );

      // 8. Santa Catarina
      case AppFlavor.sc:
        return const FlavorConfig(
          flavor: AppFlavor.sc,
          uf: 'SC',
          stateName: 'Santa Catarina',
          appName: 'Tour Santa Catarina',
          slogan: 'Ilha da Magia, praias de surf, serra catarinense e tradição',
          capital: 'Florianópolis',
          primaryColor: Color(0xFF0F766E),
          secondaryColor: Color(0xFF0284C7),
          accentColor: Color(0xFFF43F5E),
          hasCoastline: true,
          hasBoatTours: true,
        );

      // 9. Rio Grande do Sul
      case AppFlavor.rs:
        return const FlavorConfig(
          flavor: AppFlavor.rs,
          uf: 'RS',
          stateName: 'Rio Grande do Sul',
          appName: 'Tour Rio Grande do Sul',
          slogan: 'Serra Gaúcha, Gramado, cânions grandiosos e tradição pampeana',
          capital: 'Porto Alegre',
          primaryColor: Color(0xFF1E3A8A),
          secondaryColor: Color(0xFFDC2626),
          accentColor: Color(0xFF16A34A),
          hasCoastline: true,
          hasBoatTours: true,
        );

      // 10. Alagoas
      case AppFlavor.al:
        return const FlavorConfig(
          flavor: AppFlavor.al,
          uf: 'AL',
          stateName: 'Alagoas',
          appName: 'Tour Alagoas',
          slogan: 'O Caribe brasileiro, piscinas de corais e mar esmeralda',
          capital: 'Maceió',
          primaryColor: Color(0xFF0E7490),
          secondaryColor: Color(0xFF06B6D4),
          accentColor: Color(0xFFF59E0B),
          hasCoastline: true,
          hasBoatTours: true,
        );

      // 11. Paraíba
      case AppFlavor.pb:
        return const FlavorConfig(
          flavor: AppFlavor.pb,
          uf: 'PB',
          stateName: 'Paraíba',
          appName: 'Tour Paraíba',
          slogan: 'Ponta do Seixas, pôr do sol do Jacaré e piscinas de Picãozinho',
          capital: 'João Pessoa',
          primaryColor: Color(0xFF1D4ED8),
          secondaryColor: Color(0xFFE11D48),
          accentColor: Color(0xFFFBBF24),
          hasCoastline: true,
          hasBoatTours: true,
        );

      // 12. Rio Grande do Norte
      case AppFlavor.rn:
        return const FlavorConfig(
          flavor: AppFlavor.rn,
          uf: 'RN',
          stateName: 'Rio Grande do Norte',
          appName: 'Tour Rio Grande do Norte',
          slogan: 'Dunas de Genipabu, Praia da Pipa e brisa suave do Atlântico',
          capital: 'Natal',
          primaryColor: Color(0xFF0369A1),
          secondaryColor: Color(0xFFEAB308),
          accentColor: Color(0xFF059669),
          hasCoastline: true,
          hasBoatTours: true,
        );

      // 13. Sergipe
      case AppFlavor.se:
        return const FlavorConfig(
          flavor: AppFlavor.se,
          uf: 'SE',
          stateName: 'Sergipe',
          appName: 'Tour Sergipe',
          slogan: 'Cânion do Xingó, praias calmas e rica herança colonial',
          capital: 'Aracaju',
          primaryColor: Color(0xFF0284C7),
          secondaryColor: Color(0xFFF97316),
          accentColor: Color(0xFF10B981),
          hasCoastline: true,
          hasBoatTours: true,
        );

      // 14. Maranhão
      case AppFlavor.ma:
        return const FlavorConfig(
          flavor: AppFlavor.ma,
          uf: 'MA',
          stateName: 'Maranhão',
          appName: 'Tour Maranhão',
          slogan: 'Lençóis Maranhenses, casarios de azulejos e bumba meu boi',
          capital: 'São Luís',
          primaryColor: Color(0xFF1E3A8A),
          secondaryColor: Color(0xFFD97706),
          accentColor: Color(0xFFDC2626),
          hasCoastline: true,
          hasBoatTours: true,
        );

      // 15. Piauí
      case AppFlavor.pi:
        return const FlavorConfig(
          flavor: AppFlavor.pi,
          uf: 'PI',
          stateName: 'Piauí',
          appName: 'Tour Piauí',
          slogan: 'Serra da Capivara, arte rupestre milenar e Delta do Parnaíba',
          capital: 'Teresina',
          primaryColor: Color(0xFF9A3412),
          secondaryColor: Color(0xFF0284C7),
          accentColor: Color(0xFFF59E0B),
          hasCoastline: true,
          hasBoatTours: true,
        );

      // 16. Espírito Santo
      case AppFlavor.es:
        return const FlavorConfig(
          flavor: AppFlavor.es,
          uf: 'ES',
          stateName: 'Espírito Santo',
          appName: 'Tour Espírito Santo',
          slogan: 'Moqueca capixaba, praias de Guarapari e montanhas serranas',
          capital: 'Vitória',
          primaryColor: Color(0xFF0284C7),
          secondaryColor: Color(0xFFF43F5E),
          accentColor: Color(0xFF10B981),
          hasCoastline: true,
          hasBoatTours: true,
        );

      // 17. Goiás
      case AppFlavor.go:
        return const FlavorConfig(
          flavor: AppFlavor.go,
          uf: 'GO',
          stateName: 'Goiás',
          appName: 'Tour Goiás',
          slogan: 'Chapada dos Veadeiros, Pirenópolis e águas termais de Caldas',
          capital: 'Goiânia',
          primaryColor: Color(0xFF15803D),
          secondaryColor: Color(0xFFD97706),
          accentColor: Color(0xFF0284C7),
          hasCoastline: false,
          hasBoatTours: true,
        );

      // 18. Distrito Federal
      case AppFlavor.df:
        return const FlavorConfig(
          flavor: AppFlavor.df,
          uf: 'DF',
          stateName: 'Distrito Federal',
          appName: 'Tour Distrito Federal',
          slogan: 'Arquitetura monumental de Niemeyer, céu infinito e cerrado',
          capital: 'Brasília',
          primaryColor: Color(0xFF0F172A),
          secondaryColor: Color(0xFFEAB308),
          accentColor: Color(0xFF38BDF8),
          hasCoastline: false,
          hasBoatTours: true,
        );

      // 19. Mato Grosso
      case AppFlavor.mt:
        return const FlavorConfig(
          flavor: AppFlavor.mt,
          uf: 'MT',
          stateName: 'Mato Grosso',
          appName: 'Tour Mato Grosso',
          slogan: 'Pantanal norte, Chapada dos Guimarães e ecoturismo exuberante',
          capital: 'Cuiabá',
          primaryColor: Color(0xFF166534),
          secondaryColor: Color(0xFFF59E0B),
          accentColor: Color(0xFF0284C7),
          hasCoastline: false,
          hasBoatTours: true,
        );

      // 20. Mato Grosso do Sul
      case AppFlavor.ms:
        return const FlavorConfig(
          flavor: AppFlavor.ms,
          uf: 'MS',
          stateName: 'Mato Grosso do Sul',
          appName: 'Tour Mato Grosso do Sul',
          slogan: 'Bonito com rios translúcidos, Pantanal sul e fauna silvestre',
          capital: 'Campo Grande',
          primaryColor: Color(0xFF047857),
          secondaryColor: Color(0xFF0284C7),
          accentColor: Color(0xFFF97316),
          hasCoastline: false,
          hasBoatTours: true,
        );

      // 21. Amazonas
      case AppFlavor.am:
        return const FlavorConfig(
          flavor: AppFlavor.am,
          uf: 'AM',
          stateName: 'Amazonas',
          appName: 'Tour Amazonas',
          slogan: 'Floresta amazônica, Encontro das Águas e o imponente Teatro Amazonas',
          capital: 'Manaus',
          primaryColor: Color(0xFF14532D),
          secondaryColor: Color(0xFFF59E0B),
          accentColor: Color(0xFF0284C7),
          hasCoastline: false,
          hasBoatTours: true,
        );

      // 22. Pará
      case AppFlavor.pa:
        return const FlavorConfig(
          flavor: AppFlavor.pa,
          uf: 'PA',
          stateName: 'Pará',
          appName: 'Tour Pará',
          slogan: 'Gastronomia amazônica, Círio de Nazaré e Ilha de Marajó',
          capital: 'Belém',
          primaryColor: Color(0xFF15803D),
          secondaryColor: Color(0xFFB91C1C),
          accentColor: Color(0xFFEAB308),
          hasCoastline: true,
          hasBoatTours: true,
        );

      // 23. Tocantins
      case AppFlavor.to:
        return const FlavorConfig(
          flavor: AppFlavor.to,
          uf: 'TO',
          stateName: 'Tocantins',
          appName: 'Tour Tocantins',
          slogan: 'Jalapão com fervedouros cristalinos, dunas douradas e cachoeiras',
          capital: 'Palmas',
          primaryColor: Color(0xFFD97706),
          secondaryColor: Color(0xFF0284C7),
          accentColor: Color(0xFF16A34A),
          hasCoastline: false,
          hasBoatTours: true,
        );

      // 24. Rondônia
      case AppFlavor.ro:
        return const FlavorConfig(
          flavor: AppFlavor.ro,
          uf: 'RO',
          stateName: 'Rondônia',
          appName: 'Tour Rondônia',
          slogan: 'Estrada de Ferro Madeira-Mamoré e rica história amazônica',
          capital: 'Porto Velho',
          primaryColor: Color(0xFF1E3A8A),
          secondaryColor: Color(0xFF16A34A),
          accentColor: Color(0xFFF59E0B),
          hasCoastline: false,
          hasBoatTours: true,
        );

      // 25. Acre
      case AppFlavor.ac:
        return const FlavorConfig(
          flavor: AppFlavor.ac,
          uf: 'AC',
          stateName: 'Acre',
          appName: 'Tour Acre',
          slogan: 'Geoglifos ancestrais, seringais históricos e florestas virgens',
          capital: 'Rio Branco',
          primaryColor: Color(0xFF166534),
          secondaryColor: Color(0xFFDC2626),
          accentColor: Color(0xFFFBBF24),
          hasCoastline: false,
          hasBoatTours: true,
        );

      // 26. Amapá
      case AppFlavor.ap:
        return const FlavorConfig(
          flavor: AppFlavor.ap,
          uf: 'AP',
          stateName: 'Amapá',
          appName: 'Tour Amapá',
          slogan: 'Monumento Marco Zero do Equador e a monumental Fortaleza de São José',
          capital: 'Macapá',
          primaryColor: Color(0xFF065F46),
          secondaryColor: Color(0xFF0284C7),
          accentColor: Color(0xFFF59E0B),
          hasCoastline: true,
          hasBoatTours: true,
        );

      // 27. Roraima
      case AppFlavor.rr:
        return const FlavorConfig(
          flavor: AppFlavor.rr,
          uf: 'RR',
          stateName: 'Roraima',
          appName: 'Tour Roraima',
          slogan: 'Monte Roraima misterioso, lavrados abertos e cultura indígena',
          capital: 'Boa Vista',
          primaryColor: Color(0xFF0284C7),
          secondaryColor: Color(0xFF15803D),
          accentColor: Color(0xFFF59E0B),
          hasCoastline: false,
          hasBoatTours: true,
        );
    }
  }
}
