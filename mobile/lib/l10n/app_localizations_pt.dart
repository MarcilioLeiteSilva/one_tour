// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'One Tour';

  @override
  String get tabExplore => 'Explorar';

  @override
  String get tabItineraries => 'Rotas';

  @override
  String get tabMap => 'Mapas';

  @override
  String get tabSaved => 'Salvos';

  @override
  String get searchPlaceholder => 'Buscar cidades, praias, museus...';

  @override
  String get topDestinations => 'Cidades Polo em Destaque';

  @override
  String get topRated => 'Mais Amados pelos Turistas';

  @override
  String rankingBadge(int rank) {
    return '#$rank no Estado';
  }

  @override
  String ratingReviews(int count) {
    return '$count avaliações';
  }

  @override
  String get mustSee => 'Imperdível';

  @override
  String get offlineAvailable => 'Disponível Offline';

  @override
  String downloadGuide(String size) {
    return 'Baixar Guia & Mapa ($size)';
  }

  @override
  String downloading(int progress) {
    return 'Baixando $progress%';
  }

  @override
  String get createSmartTrip => 'Montar Rota Rápida';

  @override
  String get tripPlannerTitle => 'Criar Rotas';

  @override
  String get howManyDays => 'Quantos dias você vai ficar?';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias',
      one: '1 dia',
    );
    return '$_temp0';
  }

  @override
  String get whatPace => 'Qual o seu ritmo de viagem?';

  @override
  String get paceRelaxed => 'Tranquilo (2 a 3 pontos/dia)';

  @override
  String get paceModerate => 'Moderado (3 a 4 pontos/dia)';

  @override
  String get paceIntense => 'Intenso (5 a 6 pontos/dia)';

  @override
  String get whoTravels => 'Com quem você viaja?';

  @override
  String get travelerSolo => 'Viajando Solo';

  @override
  String get travelerCouple => 'Casal';

  @override
  String get travelerFamily => 'Família com Crianças';

  @override
  String get travelerFriends => 'Grupo de Amigos';

  @override
  String get interestsTitle => 'O que você mais gosta?';

  @override
  String get interestBeach => 'Praias & Litoral';

  @override
  String get interestCulture => 'História & Cultura';

  @override
  String get interestGastronomy => 'Gastronomia';

  @override
  String get interestNature => 'Ecoturismo';

  @override
  String get interestNightlife => 'Noite & Festas';

  @override
  String get btnGenerateTrip => 'Gerar Rota Otimizada';

  @override
  String dayTitle(int day) {
    return 'Dia $day';
  }

  @override
  String get lunchBreak => 'Pausa para Almoço';

  @override
  String walkTime(int min, String dist) {
    return '$min min a pé ($dist)';
  }

  @override
  String driveTime(int min, String dist) {
    return '$min min de carro ($dist)';
  }

  @override
  String get viewOnMap => 'Ver no Mapa';

  @override
  String get shareTrip => 'Compartilhar Rota';

  @override
  String likesCount(int count) {
    return '$count curtidas';
  }

  @override
  String get emptySavedTitle => 'Nenhum ponto salvo ainda';

  @override
  String get emptySavedSubtitle =>
      'Toque no coração de qualquer atração para salvar aqui e acessar offline.';

  @override
  String get houseAdsSponsored => 'Experiência Recomendada';
}
