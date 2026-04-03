import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
    Locale('it'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'CheapCheap'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get addExpense;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get addCategory;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get editCategory;

  /// No description provided for @cloneCategory.
  ///
  /// In en, this message translates to:
  /// **'Clone category'**
  String get cloneCategory;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @icon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get icon;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @importCsv.
  ///
  /// In en, this message translates to:
  /// **'Import CSV'**
  String get importCsv;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @recurrence.
  ///
  /// In en, this message translates to:
  /// **'Recurrence'**
  String get recurrence;

  /// No description provided for @recurrenceNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get recurrenceNone;

  /// No description provided for @recurrenceDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get recurrenceDaily;

  /// No description provided for @recurrenceMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get recurrenceMonthly;

  /// No description provided for @recurrenceYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get recurrenceYearly;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @daysBefore.
  ///
  /// In en, this message translates to:
  /// **'Days before'**
  String get daysBefore;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @defaultType.
  ///
  /// In en, this message translates to:
  /// **'Default type'**
  String get defaultType;

  /// No description provided for @statFocus.
  ///
  /// In en, this message translates to:
  /// **'Stat focus'**
  String get statFocus;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme mode'**
  String get themeMode;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeMandyRed.
  ///
  /// In en, this message translates to:
  /// **'Mandy Red'**
  String get themeMandyRed;

  /// No description provided for @themeDeepBlue.
  ///
  /// In en, this message translates to:
  /// **'Deep Blue'**
  String get themeDeepBlue;

  /// No description provided for @themeMango.
  ///
  /// In en, this message translates to:
  /// **'Mango'**
  String get themeMango;

  /// No description provided for @themeHippieBlue.
  ///
  /// In en, this message translates to:
  /// **'Hippie Blue'**
  String get themeHippieBlue;

  /// No description provided for @themeWasabi.
  ///
  /// In en, this message translates to:
  /// **'Wasabi'**
  String get themeWasabi;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageItalian.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get languageItalian;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// No description provided for @quests.
  ///
  /// In en, this message translates to:
  /// **'Quests'**
  String get quests;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @exp.
  ///
  /// In en, this message translates to:
  /// **'EXP'**
  String get exp;

  /// No description provided for @openCategories.
  ///
  /// In en, this message translates to:
  /// **'Open categories'**
  String get openCategories;

  /// No description provided for @addProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Add profile picture'**
  String get addProfilePicture;

  /// No description provided for @noExpenses.
  ///
  /// In en, this message translates to:
  /// **'No expenses for this month.'**
  String get noExpenses;

  /// No description provided for @defaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultLabel;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get stats;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @dayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'Day of month'**
  String get dayOfMonth;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// No description provided for @pickIcon.
  ///
  /// In en, this message translates to:
  /// **'Pick an icon'**
  String get pickIcon;

  /// No description provided for @searchIcons.
  ///
  /// In en, this message translates to:
  /// **'Search icons'**
  String get searchIcons;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @noCategory.
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get noCategory;

  /// No description provided for @csvExported.
  ///
  /// In en, this message translates to:
  /// **'CSV exported to'**
  String get csvExported;

  /// No description provided for @csvImported.
  ///
  /// In en, this message translates to:
  /// **'Imported expenses'**
  String get csvImported;

  /// No description provided for @statStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get statStrength;

  /// No description provided for @statBelly.
  ///
  /// In en, this message translates to:
  /// **'Belly'**
  String get statBelly;

  /// No description provided for @statSpirit.
  ///
  /// In en, this message translates to:
  /// **'Spirit'**
  String get statSpirit;

  /// No description provided for @statAdulthood.
  ///
  /// In en, this message translates to:
  /// **'Adulthood'**
  String get statAdulthood;

  /// No description provided for @statEasygoing.
  ///
  /// In en, this message translates to:
  /// **'Easygoing'**
  String get statEasygoing;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @addReminder.
  ///
  /// In en, this message translates to:
  /// **'Add reminder'**
  String get addReminder;

  /// No description provided for @editReminder.
  ///
  /// In en, this message translates to:
  /// **'Edit reminder'**
  String get editReminder;

  /// No description provided for @reminderFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get reminderFrequency;

  /// No description provided for @reminderDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get reminderDaily;

  /// No description provided for @reminderWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get reminderWeekly;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get reminderTime;

  /// No description provided for @reminderMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get reminderMessage;

  /// No description provided for @weekday.
  ///
  /// In en, this message translates to:
  /// **'Weekday'**
  String get weekday;

  /// No description provided for @notificationToggle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationToggle;

  /// No description provided for @notificationPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications?'**
  String get notificationPermissionTitle;

  /// No description provided for @notificationPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'CheapCheap needs notification permission to show reminder alerts.'**
  String get notificationPermissionMessage;

  /// No description provided for @exactAlarmPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow exact alarms?'**
  String get exactAlarmPermissionTitle;

  /// No description provided for @exactAlarmPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'CheapCheap needs exact alarm access to deliver reminder notifications on time. Android will open the app settings.'**
  String get exactAlarmPermissionMessage;

  /// No description provided for @reminderSavedWithoutNotifications.
  ///
  /// In en, this message translates to:
  /// **'Reminder saved without notifications. Allow notification access to turn alerts on.'**
  String get reminderSavedWithoutNotifications;

  /// No description provided for @reminderSavedWithoutExactAlarm.
  ///
  /// In en, this message translates to:
  /// **'Reminder saved without notifications. Allow exact alarm access to turn reminder alerts on.'**
  String get reminderSavedWithoutExactAlarm;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @split.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get split;

  /// No description provided for @splitEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enable split'**
  String get splitEnabled;

  /// No description provided for @splitPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get splitPayments;

  /// No description provided for @splitFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get splitFrequency;

  /// No description provided for @splitSchedule.
  ///
  /// In en, this message translates to:
  /// **'Split schedule'**
  String get splitSchedule;

  /// No description provided for @splitMessageDefault.
  ///
  /// In en, this message translates to:
  /// **'Split payment for'**
  String get splitMessageDefault;

  /// No description provided for @refund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get refund;

  /// No description provided for @refundDate.
  ///
  /// In en, this message translates to:
  /// **'Refund date'**
  String get refundDate;

  /// No description provided for @refundNote.
  ///
  /// In en, this message translates to:
  /// **'Refund note'**
  String get refundNote;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete this expense?'**
  String get confirmDelete;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @monthlyStats.
  ///
  /// In en, this message translates to:
  /// **'Monthly stats'**
  String get monthlyStats;

  /// No description provided for @currentStats.
  ///
  /// In en, this message translates to:
  /// **'Current expense stats'**
  String get currentStats;

  /// No description provided for @yearOverview.
  ///
  /// In en, this message translates to:
  /// **'Year overview'**
  String get yearOverview;

  /// No description provided for @categoryBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Category breakdown'**
  String get categoryBreakdown;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @net.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get net;

  /// No description provided for @percentage.
  ///
  /// In en, this message translates to:
  /// **'Percent'**
  String get percentage;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @questCompleted.
  ///
  /// In en, this message translates to:
  /// **'Quest completed'**
  String get questCompleted;

  /// No description provided for @welcomeIntro.
  ///
  /// In en, this message translates to:
  /// **'Welcome to CheapCheap! Track your expenses and earn quests to level up. Each expense affects your stats and helps shape your progress.'**
  String get welcomeIntro;

  /// No description provided for @welcomeProfile.
  ///
  /// In en, this message translates to:
  /// **'Add your name to start progressing with quests. Quests will not advance until your profile has a name.'**
  String get welcomeProfile;

  /// No description provided for @nextQuestsIn.
  ///
  /// In en, this message translates to:
  /// **'Next quests in'**
  String get nextQuestsIn;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;
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
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
