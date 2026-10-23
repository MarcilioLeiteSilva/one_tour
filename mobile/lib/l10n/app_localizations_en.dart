// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'One Tour';

  @override
  String get tabExplore => 'Explore';

  @override
  String get tabItineraries => 'Itineraries';

  @override
  String get tabMap => 'Map';

  @override
  String get tabSaved => 'Saved';

  @override
  String get searchPlaceholder => 'Search cities, beaches, museums...';

  @override
  String get topDestinations => 'Featured Destinations';

  @override
  String get topRated => 'Most Loved by Travelers';

  @override
  String rankingBadge(int rank) {
    return '#$rank in State';
  }

  @override
  String ratingReviews(int count) {
    return '$count reviews';
  }

  @override
  String get mustSee => 'Must See';

  @override
  String get offlineAvailable => 'Available Offline';

  @override
  String downloadGuide(String size) {
    return 'Download Guide & Map ($size)';
  }

  @override
  String downloading(int progress) {
    return 'Downloading $progress%';
  }

  @override
  String get createSmartTrip => 'Create Smart Itinerary';

  @override
  String get tripPlannerTitle => 'AI Trip Planner';

  @override
  String get howManyDays => 'How many days will you stay?';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get whatPace => 'What is your travel pace?';

  @override
  String get paceRelaxed => 'Relaxed (2 to 3 stops/day)';

  @override
  String get paceModerate => 'Moderate (3 to 4 stops/day)';

  @override
  String get paceIntense => 'Intense (5 to 6 stops/day)';

  @override
  String get whoTravels => 'Who are you traveling with?';

  @override
  String get travelerSolo => 'Solo Traveler';

  @override
  String get travelerCouple => 'Couple';

  @override
  String get travelerFamily => 'Family with Kids';

  @override
  String get travelerFriends => 'Group of Friends';

  @override
  String get interestsTitle => 'What interests you most?';

  @override
  String get interestBeach => 'Beaches & Coast';

  @override
  String get interestCulture => 'History & Culture';

  @override
  String get interestGastronomy => 'Gastronomy';

  @override
  String get interestNature => 'Ecotourism';

  @override
  String get interestNightlife => 'Nightlife & Events';

  @override
  String get btnGenerateTrip => 'Generate Optimized Trip';

  @override
  String dayTitle(int day) {
    return 'Day $day';
  }

  @override
  String get lunchBreak => 'Lunch Break';

  @override
  String walkTime(int min, String dist) {
    return '$min min walk ($dist)';
  }

  @override
  String driveTime(int min, String dist) {
    return '$min min drive ($dist)';
  }

  @override
  String get viewOnMap => 'View on Map';

  @override
  String get shareTrip => 'Share Itinerary';

  @override
  String likesCount(int count) {
    return '$count likes';
  }

  @override
  String get emptySavedTitle => 'No saved places yet';

  @override
  String get emptySavedSubtitle =>
      'Tap the heart on any attraction to save here and access offline.';

  @override
  String get houseAdsSponsored => 'Recommended Experience';
}
