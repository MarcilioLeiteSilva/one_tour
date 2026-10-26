import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'One Tour'**
  String get appTitle;

  /// No description provided for @tabExplore.
  ///
  /// In pt, this message translates to:
  /// **'Explorar'**
  String get tabExplore;

  /// No description provided for @tabItineraries.
  ///
  /// In pt, this message translates to:
  /// **'Rotas'**
  String get tabItineraries;

  /// No description provided for @tabMap.
  ///
  /// In pt, this message translates to:
  /// **'Mapas'**
  String get tabMap;

  /// No description provided for @tabSaved.
  ///
  /// In pt, this message translates to:
  /// **'Salvos'**
  String get tabSaved;

  /// No description provided for @searchPlaceholder.
  ///
  /// In pt, this message translates to:
  /// **'Buscar cidades, praias, museus...'**
  String get searchPlaceholder;

  /// No description provided for @topDestinations.
  ///
  /// In pt, this message translates to:
  /// **'Cidades Polo em Destaque'**
  String get topDestinations;

  /// No description provided for @topRated.
  ///
  /// In pt, this message translates to:
  /// **'Mais Amados pelos Turistas'**
  String get topRated;

  /// No description provided for @rankingBadge.
  ///
  /// In pt, this message translates to:
  /// **'#{rank} no Estado'**
  String rankingBadge(int rank);

  /// No description provided for @ratingReviews.
  ///
  /// In pt, this message translates to:
  /// **'{count} avaliações'**
  String ratingReviews(int count);

  /// No description provided for @mustSee.
  ///
  /// In pt, this message translates to:
  /// **'Imperdível'**
  String get mustSee;

  /// No description provided for @offlineAvailable.
  ///
  /// In pt, this message translates to:
  /// **'Disponível Offline'**
  String get offlineAvailable;

  /// No description provided for @downloadGuide.
  ///
  /// In pt, this message translates to:
  /// **'Baixar Guia & Mapa ({size})'**
  String downloadGuide(String size);

  /// No description provided for @downloading.
  ///
  /// In pt, this message translates to:
  /// **'Baixando {progress}%'**
  String downloading(int progress);

  /// No description provided for @createSmartTrip.
  ///
  /// In pt, this message translates to:
  /// **'Montar Rota Rápida'**
  String get createSmartTrip;

  /// No description provided for @tripPlannerTitle.
  ///
  /// In pt, this message translates to:
  /// **'Criar Rotas'**
  String get tripPlannerTitle;

  /// No description provided for @howManyDays.
  ///
  /// In pt, this message translates to:
  /// **'Quantos dias você vai ficar?'**
  String get howManyDays;

  /// No description provided for @daysCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 dia} other{{count} dias}}'**
  String daysCount(int count);

  /// No description provided for @whatPace.
  ///
  /// In pt, this message translates to:
  /// **'Qual o seu ritmo de viagem?'**
  String get whatPace;

  /// No description provided for @paceRelaxed.
  ///
  /// In pt, this message translates to:
  /// **'Tranquilo (2 a 3 pontos/dia)'**
  String get paceRelaxed;

  /// No description provided for @paceModerate.
  ///
  /// In pt, this message translates to:
  /// **'Moderado (3 a 4 pontos/dia)'**
  String get paceModerate;

  /// No description provided for @paceIntense.
  ///
  /// In pt, this message translates to:
  /// **'Intenso (5 a 6 pontos/dia)'**
  String get paceIntense;

  /// No description provided for @whoTravels.
  ///
  /// In pt, this message translates to:
  /// **'Com quem você viaja?'**
  String get whoTravels;

  /// No description provided for @travelerSolo.
  ///
  /// In pt, this message translates to:
  /// **'Viajando Solo'**
  String get travelerSolo;

  /// No description provided for @travelerCouple.
  ///
  /// In pt, this message translates to:
  /// **'Casal'**
  String get travelerCouple;

  /// No description provided for @travelerFamily.
  ///
  /// In pt, this message translates to:
  /// **'Família com Crianças'**
  String get travelerFamily;

  /// No description provided for @travelerFriends.
  ///
  /// In pt, this message translates to:
  /// **'Grupo de Amigos'**
  String get travelerFriends;

  /// No description provided for @interestsTitle.
  ///
  /// In pt, this message translates to:
  /// **'O que você mais gosta?'**
  String get interestsTitle;

  /// No description provided for @interestBeach.
  ///
  /// In pt, this message translates to:
  /// **'Praias & Litoral'**
  String get interestBeach;

  /// No description provided for @interestCulture.
  ///
  /// In pt, this message translates to:
  /// **'História & Cultura'**
  String get interestCulture;

  /// No description provided for @interestGastronomy.
  ///
  /// In pt, this message translates to:
  /// **'Gastronomia'**
  String get interestGastronomy;

  /// No description provided for @interestNature.
  ///
  /// In pt, this message translates to:
  /// **'Ecoturismo'**
  String get interestNature;

  /// No description provided for @interestNightlife.
  ///
  /// In pt, this message translates to:
  /// **'Noite & Festas'**
  String get interestNightlife;

  /// No description provided for @btnGenerateTrip.
  ///
  /// In pt, this message translates to:
  /// **'Gerar Rota Otimizada'**
  String get btnGenerateTrip;

  /// No description provided for @dayTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dia {day}'**
  String dayTitle(int day);

  /// No description provided for @lunchBreak.
  ///
  /// In pt, this message translates to:
  /// **'Pausa para Almoço'**
  String get lunchBreak;

  /// No description provided for @walkTime.
  ///
  /// In pt, this message translates to:
  /// **'{min} min a pé ({dist})'**
  String walkTime(int min, String dist);

  /// No description provided for @driveTime.
  ///
  /// In pt, this message translates to:
  /// **'{min} min de carro ({dist})'**
  String driveTime(int min, String dist);

  /// No description provided for @viewOnMap.
  ///
  /// In pt, this message translates to:
  /// **'Ver no Mapa'**
  String get viewOnMap;

  /// No description provided for @shareTrip.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar Rota'**
  String get shareTrip;

  /// No description provided for @likesCount.
  ///
  /// In pt, this message translates to:
  /// **'{count} curtidas'**
  String likesCount(int count);

  /// No description provided for @emptySavedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum ponto salvo ainda'**
  String get emptySavedTitle;

  /// No description provided for @emptySavedSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Toque no coração de qualquer atração para salvar aqui e acessar offline.'**
  String get emptySavedSubtitle;

  /// No description provided for @houseAdsSponsored.
  ///
  /// In pt, this message translates to:
  /// **'Experiência Recomendada'**
  String get houseAdsSponsored;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
