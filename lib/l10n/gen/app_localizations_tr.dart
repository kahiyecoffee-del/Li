// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'Dayly';

  @override
  String get appTagline => 'Hayatın zor kısmını bize bırak.';

  @override
  String get ok => 'Tamam';

  @override
  String get cancel => 'İptal';

  @override
  String get save => 'Kaydet';

  @override
  String get delete => 'Sil';

  @override
  String get edit => 'Düzenle';

  @override
  String get add => 'Ekle';

  @override
  String get done => 'Bitti';

  @override
  String get next => 'İleri';

  @override
  String get back => 'Geri';

  @override
  String get skip => 'Atla';

  @override
  String get close => 'Kapat';

  @override
  String get retry => 'Tekrar dene';

  @override
  String get confirm => 'Onayla';

  @override
  String get dismiss => 'Vazgeç';

  @override
  String get undo => 'Geri al';

  @override
  String get seeAll => 'Tümü';

  @override
  String get today => 'Bugün';

  @override
  String get yesterday => 'Dün';

  @override
  String get tomorrow => 'Yarın';

  @override
  String get thisWeek => 'Bu hafta';

  @override
  String get thisMonth => 'Bu ay';

  @override
  String get optional => 'İsteğe bağlı';

  @override
  String get learnMore => 'Daha fazla bilgi';

  @override
  String get loading => 'Yükleniyor…';

  @override
  String get saved => 'Kaydedildi';

  @override
  String get deleted => 'Silindi';

  @override
  String get premium => 'Premium';

  @override
  String get free => 'Ücretsiz';

  @override
  String minutesShort(int count) {
    return '$count dk';
  }

  @override
  String hoursMinutes(int hours, int minutes) {
    return '$hours sa $minutes dk';
  }

  @override
  String percentValue(int value) {
    return '%$value';
  }

  @override
  String outOf100(int value) {
    return '$value/100';
  }

  @override
  String get errorGeneric => 'Bir şeyler ters gitti. Tekrar dene.';

  @override
  String get errorNetwork => 'Çevrimdışısın. Bağlantını kontrol edip tekrar dene.';

  @override
  String get errorTimeout => 'Bu çok uzun sürdü. Tekrar dene.';

  @override
  String get errorUnavailable => 'Bu özellik şu anda kullanılamıyor.';

  @override
  String get errorAiUnavailable =>
      'Asistan için internet bağlantısı ve yapılandırılmış bir sunucu gerekir. Diğer her şey çevrimdışı çalışır.';

  @override
  String get errorQuota => 'Bugünkü ücretsiz yapay zeka haklarını kullandın.';

  @override
  String get errorRateLimited => 'Biraz hızlı gidiyorsun. Bir dakika bekleyip tekrar dene.';

  @override
  String get errorAuth => 'Lütfen tekrar giriş yap.';

  @override
  String get errorPermission => 'Bunu yapmaya iznin yok.';

  @override
  String get errorInvalidInput => 'Lütfen girdiğin bilgileri kontrol et.';

  @override
  String get errorEmailInUse => 'Bu hesap zaten var. Bunun yerine giriş yapmayı dene.';

  @override
  String get errorWrongCredentials => 'E-posta veya şifre eşleşmiyor.';

  @override
  String get errorWeakPassword => 'Şifren en az 8 karakter olmalı.';

  @override
  String get errorRecentLogin => 'Güvenliğin için tekrar giriş yapıp yeniden dene.';

  @override
  String get offlineBanner => 'Çevrimdışı — değişiklikler kaydedildi, sonra eşitlenecek.';

  @override
  String get navHome => 'Ana sayfa';

  @override
  String get navPlan => 'Plan';

  @override
  String get navMoney => 'Para';

  @override
  String get navLife => 'Yaşam';

  @override
  String get navAi => 'YZ';

  @override
  String get navExplore => 'Keşfet';

  @override
  String get navSaved => 'Kaydedilenler';

  @override
  String get navProfile => 'Profil';

  @override
  String get profileAndSettings => 'Profil ve ayarlar';

  @override
  String get welcomeTitle => 'Hayatın zor kısmını bize bırak.';

  @override
  String get welcomeBody =>
      'Para, karar, yemek, yazı: günlük bir problemini yaz, Dayly saniyeler içinde, telefonunda çözsün.';

  @override
  String get getStarted => 'Başla';

  @override
  String get haveAccount => 'Zaten hesabım var';

  @override
  String get signIn => 'Giriş yap';

  @override
  String get signUp => 'Hesap oluştur';

  @override
  String get signOut => 'Çıkış yap';

  @override
  String get continueWithGoogle => 'Google ile devam et';

  @override
  String get email => 'E-posta';

  @override
  String get password => 'Şifre';

  @override
  String get forgotPassword => 'Şifreni mi unuttun?';

  @override
  String get passwordResetSent => 'Sıfırlama bağlantısı için gelen kutunu kontrol et.';

  @override
  String get orDivider => 'veya';

  @override
  String get localModeNotice =>
      'Cihaz modunda çalışıyor: bulut eşitleme, yapay zeka ve satın almalar için Firebase yapılandırılmalı.';

  @override
  String get linkAccountTitle => 'Verilerini güvenceye al';

  @override
  String get linkAccountBody =>
      'Misafir hesabı kullanıyorsun. Telefon değiştirirsen verilerini korumak için Google veya e-posta bağla.';

  @override
  String get linkGoogle => 'Google hesabını bağla';

  @override
  String get linkEmail => 'E-posta bağla';

  @override
  String get accountLinked => 'Hesap bağlandı. Verilerin güvende.';

  @override
  String get guestAccount => 'Misafir hesabı';

  @override
  String get onbNameTitle => 'Adın ne?';

  @override
  String get onbNameHint => 'Adın';

  @override
  String get onbFocusTitle => 'Neyi geliştirmek istiyorsun?';

  @override
  String get onbFocusSubtitle => 'İstediğin kadar seç. Ana ekranın buna göre şekillenir.';

  @override
  String get onbIncomeTitle => 'Ortalama aylık gelir';

  @override
  String get onbIncomeSubtitle => 'Yalnızca güvenli günlük harcamanı hesaplamak için kullanılır. Gizli kalır.';

  @override
  String get onbFixedLabel => 'Sabit aylık giderler (kira, faturalar)';

  @override
  String get onbSavingsTitle => 'Aylık birikim hedefi';

  @override
  String get onbSavingsSubtitle => 'Ne kadar harcayabileceğini söylemeden önce bu tutarı ayıracağız.';

  @override
  String get onbRoutineTitle => 'Günlük rutinin';

  @override
  String get onbWake => 'Genelde şu saatte kalkarım';

  @override
  String get onbSleep => 'Genelde şu saatte yatarım';

  @override
  String get onbFoodTitle => 'Yemek tercihleri';

  @override
  String get onbDiet => 'Beslenme';

  @override
  String get onbAllergies => 'Alerjiler veya kaçındığın yiyecekler';

  @override
  String get onbAllergiesHint => 'örn. fıstık, mantar';

  @override
  String get onbNotifTitle => 'Nazik hatırlatmalar';

  @override
  String get onbNotifBody =>
      'Toplantı hatırlatmaları ve günde en fazla birkaç faydalı dürtme. İstediğin zaman değiştirebilirsin.';

  @override
  String get onbNotifAllow => 'Bildirimlere izin ver';

  @override
  String get onbLocationTitle => 'Yerel hava durumu';

  @override
  String get onbLocationBody => 'Yaklaşık konumunu kullan veya bir şehir seç. Konum isteğe bağlıdır.';

  @override
  String get onbUseLocation => 'Konumumu kullan';

  @override
  String get onbPickCity => 'Şehir ara';

  @override
  String get onbReadyTitle => 'Dayly senin için hazır!';

  @override
  String get onbReadyBody => 'Ana ekranın artık bugün senin için önemli olanı gösteriyor.';

  @override
  String get onbOpenHome => 'İlk problemimi çözelim';

  @override
  String stepOf(int current, int total) {
    return 'Adım $current/$total';
  }

  @override
  String get myLocation => 'Konumum';

  @override
  String greetingMorning(String name) {
    return 'Günaydın, $name';
  }

  @override
  String greetingAfternoon(String name) {
    return 'İyi günler, $name';
  }

  @override
  String greetingEvening(String name) {
    return 'İyi akşamlar, $name';
  }

  @override
  String get greetingNoName => 'Merhaba';

  @override
  String get dayAtAGlance => 'Gününe hızlı bir bakış.';

  @override
  String get homeToday => 'Bugün';

  @override
  String get homeNoPlan => 'Henüz bir plan yok.';

  @override
  String get homePlanDay => 'Günümü planla';

  @override
  String get homeMoney => 'Para';

  @override
  String get safeSpendingToday => 'Bugünkü güvenli harcama';

  @override
  String leftToday(String amount) {
    return 'Bugün $amount kaldı';
  }

  @override
  String overToday(String amount) {
    return 'Bugün $amount aşıldı';
  }

  @override
  String get setUpBudget => 'Bütçeni oluştur';

  @override
  String get setUpBudgetBody => 'Her gün ne kadar güvenle harcayabileceğini görmek için gelirini ekle.';

  @override
  String get homeFood => 'Yemek';

  @override
  String suggestedMeal(String meal) {
    return 'Önerilen $meal';
  }

  @override
  String get homeWellbeing => 'İyi oluş';

  @override
  String get howAreYou => 'Nasıl hissediyorsun?';

  @override
  String get lifeScore => 'Yaşam Skoru';

  @override
  String todaysGoal(int target) {
    return 'Bugünkü hedef: $target';
  }

  @override
  String get scoreNoData => 'Skorunu görmek için bugün birkaç şey kaydet.';

  @override
  String get forYou => 'Senin için';

  @override
  String importantStories(int count) {
    return 'Senin için $count haber';
  }

  @override
  String get insight => 'İçgörü';

  @override
  String get dailyGoals => 'Günlük hedefler';

  @override
  String lifeProgress(int value) {
    return 'Yaşam ilerlemesi %$value';
  }

  @override
  String streakDays(int count) {
    return '$count günlük seri';
  }

  @override
  String get streakAtRisk => 'Serini korumak için bugün herhangi bir şey kaydet.';

  @override
  String get quickAdd => 'Hızlı ekle';

  @override
  String get quickExpense => 'Harcama';

  @override
  String get quickTask => 'Görev';

  @override
  String get quickMood => 'Ruh hali';

  @override
  String get quickAsk => 'YZ’ye sor';

  @override
  String get weatherClear => 'Açık';

  @override
  String get weatherPartlyCloudy => 'Parçalı bulutlu';

  @override
  String get weatherCloudy => 'Bulutlu';

  @override
  String get weatherFog => 'Sisli';

  @override
  String get weatherDrizzle => 'Çiseleme';

  @override
  String get weatherRain => 'Yağmurlu';

  @override
  String get weatherSnow => 'Karlı';

  @override
  String get weatherThunder => 'Gök gürültülü fırtına';

  @override
  String rainChance(int value) {
    return '%$value yağış';
  }

  @override
  String highLow(int high, int low) {
    return 'Y $high° · D $low°';
  }

  @override
  String get setCityForWeather => 'Hava durumu için şehrini ekle';

  @override
  String get scoreComponentMoney => 'Para';

  @override
  String get scoreComponentHealth => 'Sağlık';

  @override
  String get scoreComponentProductivity => 'Verimlilik';

  @override
  String get scoreComponentHabits => 'Alışkanlıklar';

  @override
  String get scoreComponentMood => 'Ruh hali';

  @override
  String get scoreComponentSleep => 'Uyku';

  @override
  String get scoreComponentPlanning => 'Planlama';

  @override
  String scoreUp(int points, String reasons) {
    return 'Skorun bugün $points puan arttı; başlıca nedeni $reasons.';
  }

  @override
  String scoreDown(int points, String reasons) {
    return 'Skorun bugün $points puan düştü; başlıca nedeni $reasons.';
  }

  @override
  String get scoreSame => 'Skorun düne göre sabit.';

  @override
  String get scoreFirstDay => 'Bu ilk skorun. Neyin değiştiğini görmek için yarın tekrar gel.';

  @override
  String reasonAnd(String a, String b) {
    return '$a ve $b';
  }

  @override
  String get reasonMoneyUp => 'daha düşük harcama';

  @override
  String get reasonMoneyDown => 'daha yüksek harcama';

  @override
  String get reasonHealthUp => 'daha sağlıklı alışkanlıklar';

  @override
  String get reasonHealthDown => 'daha az sağlık alışkanlığı';

  @override
  String get reasonProductivityUp => 'tamamlanan görevler';

  @override
  String get reasonProductivityDown => 'tamamlanmayan görevler';

  @override
  String get reasonHabitsUp => 'alışkanlık ilerlemesi';

  @override
  String get reasonHabitsDown => 'kaçırılan alışkanlıklar';

  @override
  String get reasonMoodUp => 'daha iyi bir ruh hali';

  @override
  String get reasonMoodDown => 'daha düşük ruh hali';

  @override
  String get reasonSleepUp => 'daha iyi uyku';

  @override
  String get reasonSleepDown => 'azalan uyku';

  @override
  String get reasonPlanningUp => 'daha iyi planlama';

  @override
  String get reasonPlanningDown => 'daha az planlama';

  @override
  String get scoreHowCalculated => 'Nasıl hesaplanıyor?';

  @override
  String get scoreExplainer =>
      'Yaşam Skorun, takip ettiğin alanların ağırlıklı ortalamasıdır: para %20, verimlilik %20, sağlık %15, alışkanlıklar %15, ruh hali %10, uyku %10, planlama %10. Verisi olmayan alanlar hesaba katılmaz; yani bir özelliği kullanmamak skorunu düşürmez. Skorunu yapay zeka belirlemez.';

  @override
  String scoreWeakest(String area) {
    return 'En büyük fırsat: $area';
  }

  @override
  String get scoreBreakdown => 'Ayrıntılar';

  @override
  String get scoreHistory => 'Son 14 gün';

  @override
  String get unlockBreakdown => 'Bugünün ayrıntıları için kısa bir reklam izle';

  @override
  String get logSleep => 'Uyku kaydet';

  @override
  String get sleepHoursQuestion => 'Dün gece ne kadar uyudun?';

  @override
  String goalSpending(String amount) {
    return '$amount altında kal';
  }

  @override
  String goalHabit(String name, int done, int target) {
    return '$name: $done/$target';
  }

  @override
  String goalTopTask(String title) {
    return 'Bitir: $title';
  }

  @override
  String get goalLogMood => 'Ruh halini kaydet';

  @override
  String get goalLogSleep => 'Dün geceki uykunu kaydet';

  @override
  String get goalPlanDay => 'Gününü planla';

  @override
  String insightWeeklyUp(int percent) {
    return 'Bu haftaki harcaman haftalık ortalamandan %$percent daha yüksek.';
  }

  @override
  String insightWeeklyDown(int percent) {
    return 'Bu haftaki harcaman haftalık ortalamandan %$percent daha düşük.';
  }

  @override
  String insightCategoryUp(int percent, String category) {
    return 'Bu ay $category için %$percent daha fazla harcadın.';
  }

  @override
  String insightCategoryDown(int percent, String category) {
    return 'Bu ay $category için %$percent daha az harcadın.';
  }

  @override
  String insightHabitUp(int percent) {
    return 'Alışkanlık tamamlama oranın bu hafta %$percent arttı.';
  }

  @override
  String insightHabitDown(int percent) {
    return 'Alışkanlık tamamlama oranın bu hafta %$percent düştü.';
  }

  @override
  String get insightMoodSleep => 'Daha az uyuduğun günlerde ruh halini daha düşük bildirme eğilimindesin.';

  @override
  String get insightBudgetTight => 'Bugün bütçen daralıyor.';

  @override
  String get insightNone => 'Kaydetmeye devam et — yeterli veri olunca içgörüler görünecek.';

  @override
  String get planToday => 'Bugün';

  @override
  String get planWeek => 'Bu hafta';

  @override
  String get planMonth => 'Ay';

  @override
  String get planEmpty => 'Burada henüz görev yok. Bir tane ekle ya da gününü YZ’ye planlat.';

  @override
  String get planOptimize => 'Planımı optimize et';

  @override
  String planOptimized(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count görev planlandı.',
      zero: 'Planlanacak bir şey yok.',
    );
    return '$_temp0';
  }

  @override
  String get planUnscheduled => 'Herhangi bir zaman';

  @override
  String get planOverdue => 'Gecikmiş';

  @override
  String get planCompleted => 'Tamamlandı';

  @override
  String get newTask => 'Yeni görev';

  @override
  String get editTask => 'Görevi düzenle';

  @override
  String get taskTitle => 'Başlık';

  @override
  String get taskTitleHint => 'örn. Spor, Annemi ara';

  @override
  String get taskPriority => 'Öncelik';

  @override
  String get taskDuration => 'Tahmini süre';

  @override
  String get taskCategory => 'Kategori';

  @override
  String get taskDate => 'Tarih';

  @override
  String get taskTime => 'Saat';

  @override
  String get taskNoTime => 'Saat yok';

  @override
  String get taskDeadline => 'Son tarih';

  @override
  String get taskRepeat => 'Tekrar';

  @override
  String get taskAddedNextOccurrence => 'Bir sonraki tekrar eklendi.';

  @override
  String get priorityLow => 'Düşük';

  @override
  String get priorityMedium => 'Orta';

  @override
  String get priorityHigh => 'Yüksek';

  @override
  String get repeatNone => 'Asla';

  @override
  String get repeatDaily => 'Her gün';

  @override
  String get repeatWeekly => 'Her hafta';

  @override
  String get repeatMonthly => 'Her ay';

  @override
  String get taskCatWork => 'İş';

  @override
  String get taskCatPersonal => 'Kişisel';

  @override
  String get taskCatHealth => 'Sağlık';

  @override
  String get taskCatErrands => 'Ayak işleri';

  @override
  String get taskCatLearning => 'Öğrenme';

  @override
  String get taskCatSocial => 'Sosyal';

  @override
  String get taskCatOther => 'Diğer';

  @override
  String get markDone => 'Tamamlandı olarak işaretle';

  @override
  String get markNotDone => 'Tamamlanmadı olarak işaretle';

  @override
  String get moneyIncome => 'Aylık gelir';

  @override
  String get moneySpent => 'Harcanan';

  @override
  String get moneySaved => 'Birikim hedefi';

  @override
  String get moneyRemaining => 'Kalan';

  @override
  String get moneyDailySafe => 'Günlük güvenli harcama';

  @override
  String get moneyOnTrack => 'Yolunda';

  @override
  String get moneyAtRisk => 'Risk altında';

  @override
  String moneyProjected(String amount) {
    return 'Ay sonu tahmini harcama: $amount';
  }

  @override
  String moneyWeeklyLeft(String amount) {
    return 'Haftalık bütçe: $amount kaldı';
  }

  @override
  String get moneyCategories => 'Kategoriler';

  @override
  String get moneyRecent => 'Son işlemler';

  @override
  String get moneyNoTransactions => 'Henüz harcama yok. “250 öğle yemeği” yazmayı dene.';

  @override
  String get moneyBudgetSettings => 'Bütçe ayarları';

  @override
  String get moneyAddBudget => 'Limit ekle';

  @override
  String get budgetPeriodWeek => 'Haftalık';

  @override
  String get budgetPeriodMonth => 'Aylık';

  @override
  String get budgetLimit => 'Limit';

  @override
  String get budgetAllCategories => 'Tüm harcamalar';

  @override
  String get budgetCreated => 'Bütçe kaydedildi.';

  @override
  String ofLimit(String spent, String limit) {
    return '$spent / $limit';
  }

  @override
  String get currency => 'Para birimi';

  @override
  String get addExpense => 'Harcama ekle';

  @override
  String get addIncome => 'Gelir ekle';

  @override
  String get smartInputHint => 'örn. 250 öğle yemeği';

  @override
  String get smartInputHelp => 'Tutarı ve ne için olduğunu yaz. Gerisini biz dolduralım.';

  @override
  String get amount => 'Tutar';

  @override
  String get category => 'Kategori';

  @override
  String get description => 'Açıklama';

  @override
  String get date => 'Tarih';

  @override
  String get scanReceipt => 'Fiş tara';

  @override
  String get receiptReview => 'Fişi kontrol et';

  @override
  String get receiptReviewBody => 'Bunları fotoğrafından okuduk. Kaydetmeden önce yanlış görünen bir şey varsa düzelt.';

  @override
  String get receiptMerchant => 'İşyeri';

  @override
  String get receiptItems => 'Ürünler';

  @override
  String get receiptNothingFound => 'Bu fişi okuyamadık. Daha net bir fotoğraf dene ya da elle gir.';

  @override
  String get takePhoto => 'Fotoğraf çek';

  @override
  String get chooseFromGallery => 'Galeriden seç';

  @override
  String get expenseSaved => 'Harcama kaydedildi';

  @override
  String get aiParsing => 'Anlaşılıyor…';

  @override
  String get catHousing => 'Konut';

  @override
  String get catFood => 'Yemek';

  @override
  String get catTransport => 'Ulaşım';

  @override
  String get catShopping => 'Alışveriş';

  @override
  String get catBills => 'Faturalar';

  @override
  String get catEntertainment => 'Eğlence';

  @override
  String get catHealth => 'Sağlık';

  @override
  String get catSubscriptions => 'Abonelikler';

  @override
  String get catOther => 'Diğer';

  @override
  String get incomeLabel => 'Gelir';

  @override
  String get lifeHabits => 'Alışkanlıklar';

  @override
  String get lifeMood => 'Ruh hali';

  @override
  String get lifeJournal => 'Günlük';

  @override
  String get lifeFood => 'Yemek';

  @override
  String get lifePantry => 'Kiler';

  @override
  String get lifeShopping => 'Alışveriş listesi';

  @override
  String get lifeReports => 'Raporlar';

  @override
  String get lifeNews => 'Haberler';

  @override
  String get lifeAchievements => 'Başarılar';

  @override
  String get habitsEmpty => 'Küçük bir alışkanlıkla başla. Tutarlılık yoğunluktan iyidir.';

  @override
  String get newHabit => 'Yeni alışkanlık';

  @override
  String get habitName => 'Ad';

  @override
  String get habitTarget => 'Günlük hedef';

  @override
  String get habitUnit => 'Birim';

  @override
  String get habitDays => 'Günler';

  @override
  String habitStreak(int count) {
    return '$count gün';
  }

  @override
  String habitWeeklyRate(int value) {
    return 'Bu hafta: %$value tamamlandı';
  }

  @override
  String get habitArchive => 'Alışkanlığı arşivle';

  @override
  String get habitWater => 'Su';

  @override
  String get habitReading => 'Okuma';

  @override
  String get habitExercise => 'Egzersiz';

  @override
  String get habitMeditation => 'Meditasyon';

  @override
  String get habitSleep => 'Uyku';

  @override
  String get habitCustom => 'Özel';

  @override
  String habitIncrement(String name) {
    return '$name için bir ekle';
  }

  @override
  String habitDecrement(String name) {
    return '$name için bir azalt';
  }

  @override
  String get moodGreat => 'Harika';

  @override
  String get moodGood => 'İyi';

  @override
  String get moodOkay => 'İdare eder';

  @override
  String get moodLow => 'Düşük';

  @override
  String get moodBad => 'Bitkin';

  @override
  String get moodWhy => 'Neden? (isteğe bağlı)';

  @override
  String get moodSaved => 'Ruh hali kaydedildi';

  @override
  String get moodHistory => 'Bu hafta';

  @override
  String get moodDisclaimer =>
      'Ruh hali takibi yalnızca kendini gözlemlemek içindir; tıbbi veya ruh sağlığı değerlendirmesi değildir. Zorlanıyorsan lütfen bir uzmana ya da güvendiğin birine ulaş.';

  @override
  String get journalEmpty => 'Düşüncelerin için özel bir alan. Kayıtlar bu cihazda şifreli kalır.';

  @override
  String get journalNew => 'Yeni kayıt';

  @override
  String get journalHint => 'Günün nasıl geçti?';

  @override
  String get journalPrivacy =>
      'Bu cihazda şifrelenir. Asla eşitlenmez. Yalnızca Gizlilik ayarlarında izin verirsen YZ ile paylaşılır.';

  @override
  String get journalSummarize => 'Haftamı özetle';

  @override
  String get foodWhatToEat => 'Ne yesem?';

  @override
  String get foodMealBreakfast => 'Kahvaltı';

  @override
  String get foodMealLunch => 'Öğle yemeği';

  @override
  String get foodMealDinner => 'Akşam yemeği';

  @override
  String get foodMealSnack => 'Ara öğün';

  @override
  String foodCalories(int value) {
    return '$value kcal';
  }

  @override
  String foodMacros(int p, int c, int f) {
    return 'P ${p}g · K ${c}g · Y ${f}g';
  }

  @override
  String get foodDifficultyEasy => 'Kolay';

  @override
  String get foodDifficultyMedium => 'Orta';

  @override
  String get foodDifficultyHard => 'Zor';

  @override
  String get foodCostLow => 'Ekonomik';

  @override
  String get foodCostMedium => 'Orta maliyet';

  @override
  String get foodCostHigh => 'Yüksek maliyet';

  @override
  String foodEstimatedCost(String amount) {
    return 'Yaklaşık $amount';
  }

  @override
  String get foodRefreshLocal => 'Kilerimden öner';

  @override
  String get foodGenerateAi => 'YZ ile plan oluştur';

  @override
  String get foodIngredients => 'Malzemeler';

  @override
  String get foodSteps => 'Adımlar';

  @override
  String foodMissing(String items) {
    return 'Eksik: $items';
  }

  @override
  String get foodAddMissing => 'Eksikleri alışveriş listesine ekle';

  @override
  String foodAddedToList(int count) {
    return '$count ürün eklendi';
  }

  @override
  String get foodPreferences => 'Yemek tercihleri';

  @override
  String get foodSkill => 'Yemek becerisi';

  @override
  String get foodBudget => 'Yemek bütçesi';

  @override
  String get skillBeginner => 'Başlangıç';

  @override
  String get skillIntermediate => 'Orta';

  @override
  String get skillAdvanced => 'İleri';

  @override
  String get budgetLow => 'Düşük';

  @override
  String get budgetMedium => 'Orta';

  @override
  String get budgetHigh => 'Yüksek';

  @override
  String get dietNone => 'Kısıtlama yok';

  @override
  String get dietVegetarian => 'Vejetaryen';

  @override
  String get dietVegan => 'Vegan';

  @override
  String get dietPescatarian => 'Pesketaryen';

  @override
  String get dietKeto => 'Keto';

  @override
  String get dietHalal => 'Helal';

  @override
  String get dietGlutenFree => 'Glutensiz';

  @override
  String get nutritionDisclaimer => 'Besin değerleri tahminidir.';

  @override
  String get pantryEmpty => 'Elindekileri kullanan yemek fikirleri için evdeki malzemeleri ekle.';

  @override
  String get pantryAddHint => 'örn. tavuk, pirinç, domates';

  @override
  String pantryCanMake(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Elindekilerle $count yemek yapabilirsin.',
      zero: 'Yemek önerileri için birkaç malzeme daha ekle.',
    );
    return '$_temp0';
  }

  @override
  String get shoppingEmpty => 'Listen boş.';

  @override
  String get shoppingAddHint => 'Ürün ekle';

  @override
  String get shoppingClearChecked => 'İşaretlileri temizle';

  @override
  String get shopProduce => 'Meyve & sebze';

  @override
  String get shopMeat => 'Et & balık';

  @override
  String get shopDairy => 'Süt ürünleri & yumurta';

  @override
  String get shopBakery => 'Fırın';

  @override
  String get shopPantry => 'Kiler';

  @override
  String get shopFrozen => 'Donuk';

  @override
  String get shopDrinks => 'İçecekler';

  @override
  String get shopHousehold => 'Ev ihtiyaçları';

  @override
  String get shopPersonalCare => 'Kişisel bakım';

  @override
  String get shopOther => 'Diğer';

  @override
  String get aiTitle => 'Asistan';

  @override
  String get aiInputHint => 'Günün hakkında her şeyi sor…';

  @override
  String get aiSend => 'Gönder';

  @override
  String get aiThinking => 'Düşünüyor…';

  @override
  String get aiEmptyTitle => 'Bugün nasıl yardımcı olabilirim?';

  @override
  String get aiSuggestion1 => 'Günümü planla';

  @override
  String get aiSuggestion2 => 'Bu ay 10.000 biriktirmek istiyorum';

  @override
  String get aiSuggestion3 => 'Evde tavuk, pirinç ve domates var';

  @override
  String get aiSuggestion4 => 'Bu ay neden fazla harcadım?';

  @override
  String get aiSuggestion5 => 'Benim hakkımda ne biliyorsun?';

  @override
  String aiCreditsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bugün $count ücretsiz hakkın kaldı',
      zero: 'Bugün ücretsiz hakkın kalmadı',
    );
    return '$_temp0';
  }

  @override
  String get aiUnlimited => 'Premium · sınırsız';

  @override
  String aiWatchAd(int count) {
    return 'Reklam izle, +$count hak kazan';
  }

  @override
  String get aiGoPremium => 'Sınırsız YZ için Premium’a geç';

  @override
  String get aiRewardEarned => 'Teşekkürler! Ek hak kazandın.';

  @override
  String get aiRewardUnavailable => 'Şu anda reklam yok. Daha sonra tekrar dene.';

  @override
  String get aiActionsProposed => 'Önerilen işlemler';

  @override
  String aiActionCreateTask(String title) {
    return '“$title” görevini ekle';
  }

  @override
  String aiActionCreateTaskAt(String title, String when) {
    return '$when için “$title” ekle';
  }

  @override
  String get aiActionOptimize => 'Bugünün planını optimize et';

  @override
  String aiActionBudget(String period, String amount) {
    return '$amount tutarında $period bütçe oluştur';
  }

  @override
  String aiActionExpense(String amount, String category) {
    return '$category için $amount kaydet';
  }

  @override
  String aiActionSavings(String amount) {
    return 'Birikim hedefini $amount yap';
  }

  @override
  String aiActionMeal(String date) {
    return '$date için yemek planı oluştur';
  }

  @override
  String aiActionShopping(int count) {
    return 'Alışveriş listesine $count ürün ekle';
  }

  @override
  String aiActionHabit(String name) {
    return '“$name” alışkanlığını başlat';
  }

  @override
  String aiActionMood(String mood) {
    return 'Ruh halini kaydet: $mood';
  }

  @override
  String aiActionMemory(String content) {
    return 'Hatırla: $content';
  }

  @override
  String get aiActionDone => 'Yapıldı';

  @override
  String get aiActionDismissed => 'Vazgeçildi';

  @override
  String get aiActionFailed => 'Bu işlem tamamlanamadı.';

  @override
  String aiMemorySaved(String content) {
    return 'Hafızaya kaydedildi: $content';
  }

  @override
  String get aiNewChat => 'Yeni sohbet';

  @override
  String get aiDisclaimer =>
      'YZ hata yapabilir. Asla para transferi yapmaz ve her değişiklik senin onayını gerektirir.';

  @override
  String aiDataNotice(String scopes) {
    return 'Kullanılan: $scopes. Gizlilik ayarlarından değiştir.';
  }

  @override
  String get aiNoScopes => 'yalnızca temel profil bilgilerin';

  @override
  String get weeklyReport => 'Haftan';

  @override
  String get weeklyReportSubtitle => '60 saniyede haftan.';

  @override
  String get monthlyReport => 'Aylık Yaşam Raporu';

  @override
  String get reportScore => 'Yaşam Skoru';

  @override
  String reportScoreChange(int from, int to) {
    return '$from → $to';
  }

  @override
  String get reportMoney => 'Para';

  @override
  String reportSaved(String amount) {
    return 'Önceki döneme göre tasarruf: $amount';
  }

  @override
  String reportSpendChange(String percent) {
    return 'Harcama önceki döneme göre %$percent';
  }

  @override
  String get reportHabits => 'Alışkanlıklar';

  @override
  String get reportMood => 'Ortalama ruh hali';

  @override
  String reportMoodValue(String value) {
    return '$value/10';
  }

  @override
  String get reportProductivity => 'Verimlilik';

  @override
  String get reportSleep => 'Ortalama uyku';

  @override
  String get reportNextWeek => 'Gelecek hafta';

  @override
  String get reportNextMonth => 'Gelecek ay';

  @override
  String get reportAiSummary => 'YZ özeti';

  @override
  String get reportGenerateSummary => 'Özetimi yaz';

  @override
  String get reportNoData => 'Henüz yeterli veri yok.';

  @override
  String suggestReduceCategory(String category) {
    return '$category harcamalarını azalt';
  }

  @override
  String get suggestSleepEarlier => '30 dakika erken yat';

  @override
  String get suggestKeepStreak => 'Mevcut alışkanlık serini koru';

  @override
  String get suggestPlanMore => 'Her gün en az bir görev planla';

  @override
  String get suggestLogMood => 'Ruh halini her gün kaydet';

  @override
  String get suggestStartHabit => 'Küçük bir alışkanlık başlat';

  @override
  String get achievements => 'Başarılar';

  @override
  String get badgeFirstWeek => 'İlk Hafta';

  @override
  String get badgeFirstWeekDesc => '7 farklı gün aktif oldun';

  @override
  String get badgeBudgetMaster => 'Bütçe Ustası';

  @override
  String get badgeBudgetMasterDesc => '7 gün üst üste günlük limitinde kaldın';

  @override
  String get badgeStreak => '7 Günlük Seri';

  @override
  String get badgeStreakDesc => '7 gün üst üste kayıt yaptın';

  @override
  String get badgeHealthyWeek => 'Sağlıklı Hafta';

  @override
  String get badgeHealthyWeekDesc => 'Bir haftada sağlık alışkanlıklarının %80’ini tamamladın';

  @override
  String get badgeEarlyBird => 'Erkenci Kuş';

  @override
  String get badgeEarlyBirdDesc => 'Sabah 9’dan önce 5 görev tamamladın';

  @override
  String get badgePlanner => 'Planlayıcı';

  @override
  String get badgePlannerDesc => '7 farklı gün için görev planladın';

  @override
  String get badgeMoneySaver => 'Tasarruf Ustası';

  @override
  String get badgeMoneySaverDesc => 'Aylık birikim hedefine ulaştın';

  @override
  String badgeUnlocked(String name) {
    return 'Başarı kazanıldı: $name';
  }

  @override
  String get newsWhyMatters => 'Bu neden önemli';

  @override
  String get newsTopics => 'Konular';

  @override
  String get newsTopicTechnology => 'Teknoloji';

  @override
  String get newsTopicFinance => 'Finans';

  @override
  String get newsTopicSports => 'Spor';

  @override
  String get newsTopicWorld => 'Dünya';

  @override
  String get newsTopicScience => 'Bilim';

  @override
  String get newsTopicEntertainment => 'Eğlence';

  @override
  String get newsUnavailable => 'Haberler şu anda kullanılamıyor.';

  @override
  String get openArticle => 'Haberi aç';

  @override
  String get settings => 'Ayarlar';

  @override
  String get settingsProfile => 'Profil';

  @override
  String get settingsAppearance => 'Görünüm';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeDark => 'Koyu';

  @override
  String get highContrast => 'Yüksek kontrast';

  @override
  String get language => 'Dil';

  @override
  String get languageSystem => 'Cihaz dili';

  @override
  String get settingsNotifications => 'Bildirimler';

  @override
  String get notifOff => 'Kapalı';

  @override
  String get notifLow => 'Yalnızca hatırlatmalar';

  @override
  String get notifNormal => 'Hatırlatmalar + günlük dürtmeler';

  @override
  String get notifExplain => 'Günde birkaç bildirimden fazlasını göndermeyiz ve gece hiçbir şey göndermeyiz.';

  @override
  String get settingsPrivacy => 'Gizlilik ve veriler';

  @override
  String get settingsAiMemory => 'YZ hafızası';

  @override
  String get settingsAccount => 'Hesap';

  @override
  String get settingsAbout => 'Hakkında';

  @override
  String get privacyPolicy => 'Gizlilik Politikası';

  @override
  String get termsOfService => 'Kullanım Koşulları';

  @override
  String get analyticsToggle => 'Anonim kullanım analitiğini paylaş';

  @override
  String get crashToggle => 'Çökme raporlarını gönder';

  @override
  String get personalizedAdsToggle => 'Kişiselleştirilmiş reklamlar';

  @override
  String get aiDataTitle => 'YZ’nin görebildikleri';

  @override
  String get aiDataBody =>
      'Asistanı kullandığında Dayly mesajını ve yalnızca aşağıda izin verdiğin verileri sunucumuza gönderir; sunucu da yanıt üretmek için bunları bir YZ sağlayıcısına iletir. Dayly bu verileri YZ modeli eğitmek için kullanmaz. Açmadıkça günlüğün asla paylaşılmaz.';

  @override
  String get scopeMoney => 'Para (bütçe toplamları ve kategoriler)';

  @override
  String get scopeTasks => 'Görevler ve takvim';

  @override
  String get scopeHabits => 'Alışkanlıklar';

  @override
  String get scopeMood => 'Ruh hali ve uyku (son 7 gün)';

  @override
  String get scopeFood => 'Yemek tercihleri ve kiler';

  @override
  String get scopeJournal => 'Günlük (son 5 kayıt)';

  @override
  String get scopeShortMoney => 'para';

  @override
  String get scopeShortTasks => 'görevler';

  @override
  String get scopeShortHabits => 'alışkanlıklar';

  @override
  String get scopeShortMood => 'ruh hali';

  @override
  String get scopeShortFood => 'yemek';

  @override
  String get scopeShortJournal => 'günlük';

  @override
  String get memoryEnabledToggle => 'Asistanın bazı şeyleri hatırlamasına izin ver';

  @override
  String get memoryEmpty => 'Asistan henüz senin hakkında bir şey kaydetmedi.';

  @override
  String get memoryDeleteAll => 'Tüm anıları sil';

  @override
  String memoryLimit(int used, int limit) {
    return '$used/$limit anı kullanıldı';
  }

  @override
  String get memCatPreferences => 'Tercihler';

  @override
  String get memCatGoals => 'Hedefler';

  @override
  String get memCatHabits => 'Alışkanlıklar';

  @override
  String get memCatFood => 'Yemek';

  @override
  String get memCatBudget => 'Bütçe';

  @override
  String get memCatSchedule => 'Program';

  @override
  String get exportData => 'Verilerimi dışa aktar';

  @override
  String exportDone(String path) {
    return 'Dışa aktarma şuraya kaydedildi: $path';
  }

  @override
  String get deleteDataSection => 'Verileri sil';

  @override
  String get deleteJournal => 'Tüm günlük kayıtlarını sil';

  @override
  String get deleteExpenses => 'Tüm harcamaları sil';

  @override
  String get deleteMemories => 'YZ hafızasını sil';

  @override
  String get deleteChats => 'YZ sohbetlerini sil';

  @override
  String get deleteAccount => 'Hesabı sil';

  @override
  String get deleteAccountBody =>
      'Bu işlem hesabını ve buluttaki ve bu cihazdaki tüm verileri kalıcı olarak siler. Aktif abonelikler Google Play’den iptal edilmelidir.';

  @override
  String get deleteConfirmTitle => 'Emin misin?';

  @override
  String get deleteConfirmBody => 'Bu işlem geri alınamaz.';

  @override
  String get typeDeleteToConfirm => 'Onaylamak için DELETE yaz';

  @override
  String get syncStatus => 'Eşitleme';

  @override
  String get syncUpToDate => 'Güncel';

  @override
  String syncPending(int count) {
    return '$count değişiklik eşitlenmeyi bekliyor';
  }

  @override
  String get syncLocalOnly => 'Yalnızca bu cihazda';

  @override
  String version(String value) {
    return 'Sürüm $value';
  }

  @override
  String get placeholderLegal => 'Bu bir yer tutucudur. Yayından önce yayımlanmış politikanla değiştir.';

  @override
  String get city => 'Şehir';

  @override
  String get newsTopicsSetting => 'Haber konuları';

  @override
  String get premiumTitle => 'Dayly Premium';

  @override
  String get premiumSubtitle => 'Daha fazla içgörü, reklamsız, sınırsız asistan.';

  @override
  String get premiumFeatureAi => 'Sınırsız YZ asistanı (adil kullanım)';

  @override
  String get premiumFeatureScore => 'Tam Yaşam Skoru ayrıntıları ve geçmişi';

  @override
  String get premiumFeatureNoAds => 'Reklamsız';

  @override
  String get premiumFeatureAnalytics => 'Gelişmiş analizler ve aylık raporlar';

  @override
  String get premiumFeatureMeals => 'Sınırsız YZ yemek planı';

  @override
  String get premiumFeatureMemory => 'Sınırsız YZ hafızası';

  @override
  String get premiumMonthly => 'Aylık';

  @override
  String get premiumYearly => 'Yıllık';

  @override
  String get premiumSubscribe => 'Abone ol';

  @override
  String get premiumRestore => 'Satın alımları geri yükle';

  @override
  String get premiumActive => 'Premium üyesin. Teşekkürler!';

  @override
  String get premiumManage => 'Aboneliği Google Play’de yönet';

  @override
  String get premiumUnavailable => 'Abonelikler şu anda bu cihazda kullanılamıyor.';

  @override
  String get premiumPending => 'Satın alma bekleniyor…';

  @override
  String get premiumSuccess => 'Premium’a hoş geldin!';

  @override
  String get premiumDisclosure =>
      'Abonelikler iptal edilene kadar gösterilen fiyattan otomatik olarak yenilenir. Yenilemeden en az 24 saat önce Google Play’den istediğin zaman iptal edebilirsin. Ödeme Google Play hesabından alınır.';

  @override
  String get premiumLocked => 'Premium özellik';

  @override
  String get tryWithAd => 'Kısa bir reklamla bir kez dene';

  @override
  String get notifTaskTitle => 'Yaklaşıyor';

  @override
  String notifTaskBody(String title) {
    return '“$title” 30 dakika sonra başlıyor.';
  }

  @override
  String get notifSpendingTitle => 'Hızlı kontrol';

  @override
  String get notifSpendingBody => 'Bugünkü harcamalarını kaydetmedin.';

  @override
  String get notifBudgetTitle => 'Bütçe';

  @override
  String get notifBudgetBody => 'Bütçen daralıyor. Bugün için güvenli tutarın burada.';

  @override
  String get notifStreakTitle => 'Devam et';

  @override
  String notifStreakBody(int count) {
    return '$count günlük serin risk altında.';
  }

  @override
  String get notifMoodTitle => 'Kayıt zamanı';

  @override
  String get notifMoodBody => 'Bugün nasıl hissediyorsun?';

  @override
  String get notifWeeklyTitle => '60 saniyede haftan';

  @override
  String get notifWeeklyBody => 'Haftalık değerlendirmen hazır.';

  @override
  String get focusMoney => 'Para';

  @override
  String get focusHealth => 'Sağlık';

  @override
  String get focusProductivity => 'Verimlilik';

  @override
  String get focusFood => 'Yemek';

  @override
  String get focusHabits => 'Alışkanlıklar';

  @override
  String get focusPlanning => 'Planlama';

  @override
  String weekdayShort(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': 'Pzt',
      '2': 'Sal',
      '3': 'Çar',
      '4': 'Per',
      '5': 'Cum',
      '6': 'Cmt',
      'other': 'Paz',
    });
    return '$_temp0';
  }

  @override
  String mascotTip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bugün senin için $count önerim var.',
      zero: 'Bugün acil bir şey yok — tadını çıkar.',
    );
    return '$_temp0';
  }

  @override
  String get mascotAsk => 'Lio’ya bir şey sormak için dokun';

  @override
  String get allGoalsDone => 'Bugünün tüm hedefleri tamam — harikasın!';

  @override
  String get lioName => 'Lio, yol arkadaşın';

  @override
  String get lioAsk => 'Lio’ya sor';

  @override
  String get lioAnother => 'Bir tane daha';

  @override
  String get lioHide => 'Lio’yu gizle';

  @override
  String get lioHidden => 'Lio dinleniyor. Ayarlardan geri getirebilirsin.';

  @override
  String get lioSetting => 'Lio yol arkadaşı';

  @override
  String get lioSettingHelp => 'Lio uygulamada seninle gezer; ipuçları ve biraz ilham verir.';

  @override
  String lioGoalsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bugün $count hedefin kaldı. Teker teker gidelim.',
      one: 'Bugün bir hedefin kaldı. Yaparsın!',
    );
    return '$_temp0';
  }

  @override
  String get lioAllDone => 'Bugünün tüm hedefleri tamam. Seninle gurur duyuyorum!';

  @override
  String get lioOverBudget => 'Bugün bütçeyi biraz aştık. Yarın biraz yavaşlarız, dert etme.';

  @override
  String lioUnderBudget(String amount) {
    return 'Bugün için hâlâ $amount alanın var. Güzel dengeliyorsun!';
  }

  @override
  String lioStreak(int days) {
    return '$days günlük seri! Ateşi canlı tutalım.';
  }

  @override
  String get lioMoodCheck => 'Nasıl hissediyorsun? Kısa bir ruh hali kaydı sana daha iyi yardım etmemi sağlar.';

  @override
  String get lioNight => 'Saat ilerledi. İyi bir uyku yarın için en iyi plandır.';

  @override
  String get lioTipHome1 => 'Her şeyi iki saniyede kaydetmek için + butonuna dokun.';

  @override
  String get lioTipHome2 => 'Gününü yenilemek için aşağı çek.';

  @override
  String get lioTipPlan1 => 'En zor işini başa koy; enerjin en çok günün başında.';

  @override
  String get lioTipPlan2 => '15 dakikadan kısa işler mi var? Hepsini art arda bitir.';

  @override
  String get lioTipPlan3 => 'Gününü planlamamı iste, her şeyi senin için sıralayayım.';

  @override
  String get lioTipMoney1 => '“250 öğle yemeği” yazman yeterli, gerisini ben hallederim.';

  @override
  String get lioTipMoney2 => 'Küçük günlük tasarruflar büyük aylar yapar.';

  @override
  String get lioTipMoney3 => 'Fişin fotoğrafını çek, toplamı senin için okurum.';

  @override
  String get lioTipLife1 => 'İki dakikalık günlük, bütün günün gürültüsünü dindirebilir.';

  @override
  String get lioTipLife2 => 'Buzdolabında ne olduğunu söyle, sana bir yemek önereyim.';

  @override
  String get lioTipLife3 => 'Alışkanlıklar küçükken kalıcı olur. Bir bardak suyla başla.';

  @override
  String get lioInspire1 => 'Her gün atılan küçük adımlar, bir gün yapılacak büyük planlardan iyidir.';

  @override
  String get lioInspire2 => 'Her şeyi yapmak zorunda değilsin. Sadece sıradaki doğru şeyi.';

  @override
  String get lioInspire3 => 'Dinlenmek planın bir parçası, plandan kaçış değil.';

  @override
  String get lioInspire4 => 'Mükemmellik değil, ilerleme.';

  @override
  String get lioInspire5 => 'Sakin bir sabah, güzel bir gün getirir.';

  @override
  String get lioInspire6 => 'Bugün geldiğin yolla gurur duy.';

  @override
  String get lioInspire7 => 'Biraz su iç. Gelecekteki sen teşekkür ediyor.';

  @override
  String get lioInspire8 => 'Küçük bir harcamaya “hayır” demek, büyük bir hayale “evet” demektir.';

  @override
  String get lioInspire9 => '“Bitti” çok güzel bir kelime.';

  @override
  String get lioInspire10 => 'Derin bir nefes al. Sandığından daha iyi gidiyorsun.';

  @override
  String get lioInspire11 => 'Bugün küçük bir şeye başlamak için güzel bir gün.';

  @override
  String get lioInspire12 => 'Kendine nazik olmak da sayılır.';

  @override
  String brainGreeting(String name) {
    return 'Merhaba $name! Ben Lio. Bana planını, paranı, yemeği ya da nasıl gittiğini sorabilirsin.';
  }

  @override
  String get brainGreetingNoName =>
      'Merhaba! Ben Lio. Bana planını, paranı, yemeği ya da nasıl gittiğini sorabilirsin.';

  @override
  String get brainThanks => 'Ne demek! İhtiyacın olduğunda hep buradayım.';

  @override
  String get brainPlanNone =>
      'Bugünkü planın boş. En önemli tek işini ekleyerek başla — Plan sekmesinde + butonuna dokun.';

  @override
  String brainPlanList(int count) {
    return 'Bugün listende $count iş var:';
  }

  @override
  String brainPlanNext(String title) {
    return '“$title” ile başla — o bitince gerisi daha hafif gelir.';
  }

  @override
  String get brainPlanAllDone => 'Bugünkü listedeki her şey bitti. Dinlen ya da yarına erkenden başla.';

  @override
  String get brainMoneyNoBudget =>
      'Henüz bütçe belirlemedin. Para bölümüne aylık gelirini ekle, sana güvenli günlük tutarı hesaplayayım.';

  @override
  String brainMoneySafe(String left, String safe) {
    return 'Bugün hâlâ $left harcayabilirsin. Güvenli günlük tutarın $safe.';
  }

  @override
  String brainMoneyOver(String over) {
    return 'Bugünkü güvenli tutarı $over aştın. Günün kalanında biraz yavaşlayalım.';
  }

  @override
  String get brainMoneyTip => 'İpucu: harcamaları hemen kaydet — “250 öğle yemeği” yazman yeterli.';

  @override
  String brainFood(String meal, int minutes) {
    return '$meal nasıl olur? Yaklaşık $minutes dakika sürer. Daha fazla fikir Yemek bölümünde.';
  }

  @override
  String get brainFoodNone => 'Kilerine evdekileri ekle, onlarla yapılacak yemekler önereyim.';

  @override
  String brainScore(int score) {
    return 'Bugünkü Yaşam Skorun $score/100.';
  }

  @override
  String get brainScoreNone => 'Bugün henüz skorun yok — ruh halini kaydet ya da bir hedefi bitir, hemen görünür.';

  @override
  String get brainFeelLow =>
      'Bugün ağır geldiği için üzgünüm. Küçük bir şey dene: bir bardak su, kısa bir yürüyüş ya da üç yavaş nefes. Ruh halini kaydetmek de iyi gelebilir.';

  @override
  String get brainSleep =>
      'Her gün aynı saatte yatmaya çalış, yatmadan 30 dakika önce ekranı bırak. Uykunu Ana sayfadan kaydedebilirsin.';

  @override
  String get brainHabit =>
      'Küçük alışkanlıklar kazanır. İki dakikadan kısa süren bir şey seç ve Alışkanlıklar’da takip et.';

  @override
  String get brainHelp =>
      'Aşağıdan bir konu seç — para, karar, yemek, mesaj ya da hızlı bir hesap — seni adım adım götüreyim.';

  @override
  String get brainFallback => 'Bunu henüz öğreniyorum. Bana planını, paranı, yemeği ya da günün nasıl geçtiğini sor.';

  @override
  String get brainAnswerLabel => 'Lio · telefonunda';

  @override
  String homeHello(String name) {
    return 'Merhaba $name 👋';
  }

  @override
  String get homeHelloNoName => 'Merhaba 👋';

  @override
  String get homeQuestion => 'Bugün neyi çözelim?';

  @override
  String get problemHint => 'Bir problemini yaz…';

  @override
  String get problemEx1 => '3.000 TL param kaldı, ay sonuna 20 gün var';

  @override
  String get problemEx2 => '1 L 45 TL mi, 1,5 L 60 TL mi daha ucuz?';

  @override
  String get problemEx3 => 'Evde yumurta, domates ve peynir var';

  @override
  String get problemEx4 => 'iPhone mu Samsung mu?';

  @override
  String get problemEx5 => '1.840 TL hesap, 4 kişiyiz';

  @override
  String get problemEx6 => '1.299 TL\'ye %30 indirim';

  @override
  String get problemEx7 => '31 Aralık\'a kaç gün var?';

  @override
  String get solve => 'Çöz';

  @override
  String get voiceInput => 'Sesle anlat';

  @override
  String get photoInput => 'Fotoğraf';

  @override
  String get listening => 'Dinliyorum…';

  @override
  String get voiceUnavailable => 'Bu cihazda sesle yazma kullanılamıyor.';

  @override
  String get photoNoText => 'Bu fotoğrafta okunabilir bir yazı bulamadım.';

  @override
  String get quickMoney => 'Para';

  @override
  String get quickDecide => 'Karar ver';

  @override
  String get quickFood => 'Yemek';

  @override
  String get quickCalc => 'Hesapla';

  @override
  String get quickWrite => 'Yaz';

  @override
  String get quickPlan => 'Planla';

  @override
  String get recentlySolved => 'Son çözdüklerin';

  @override
  String get solutionTitle => 'Çözüm';

  @override
  String get solvedOnDevice => 'Telefonunda hesaplandı';

  @override
  String get savedToast => 'Kaydedildi';

  @override
  String get askLioAbout => 'Bunu Lio’ya sor';

  @override
  String get solveAnother => 'Başka bir şey çöz';

  @override
  String get rowPerDay => 'Günlük';

  @override
  String get rowPerWeek => 'Haftalık';

  @override
  String get rowDays => 'Gün';

  @override
  String get rowTotal => 'Toplam';

  @override
  String get rowYouSave => 'Tasarruf';

  @override
  String get rowTax => 'Vergi';

  @override
  String get rowIncrease => 'Artış';

  @override
  String get rowPrice => 'Fiyat';

  @override
  String get rowPerPerson => 'Kişi başı';

  @override
  String get rowPeople => 'Kişi';

  @override
  String get rowTip => 'Bahşiş';

  @override
  String get rowMonthly => 'Aylık';

  @override
  String get rowMonths => 'Ay';

  @override
  String get rowCash => 'Peşin fiyat';

  @override
  String get rowExtra => 'Fazladan ödeme';

  @override
  String get rowDistance => 'Mesafe';

  @override
  String get rowFuel => 'Yakıt';

  @override
  String get rowYearly => 'Yıllık';

  @override
  String get rowDate => 'Tarih';

  @override
  String runwayHeadline(String amount) {
    return 'Günde $amount harcayabilirsin.';
  }

  @override
  String runwayMonthEnd(int days) {
    return 'Ay sonuna kadar sayıldı ($days gün, bugün dahil).';
  }

  @override
  String discountHeadline(String amount) {
    return '$amount ödersin.';
  }

  @override
  String vatHeadline(String amount) {
    return 'KDV dahil toplam: $amount.';
  }

  @override
  String raiseHeadline(String amount) {
    return 'Yeni tutar: $amount.';
  }

  @override
  String percentOfHeadline(String percent, String base, String result) {
    return '$base sayısının %$percent kadarı $result eder.';
  }

  @override
  String splitHeadline(String amount) {
    return 'Kişi başı $amount düşüyor.';
  }

  @override
  String installmentMore(String amount, String percent) {
    return 'Taksitli almak peşine göre $amount daha pahalı (%$percent).';
  }

  @override
  String get installmentNoMore => 'Taksit peşinden pahalı değil; bölmek mantıklı.';

  @override
  String installmentTotal(String amount) {
    return 'Toplamda $amount ödersin.';
  }

  @override
  String unitPriceHeadline(int n, String price, String unit) {
    return '$n. seçenek daha ucuz: $unit başına $price.';
  }

  @override
  String unitPriceSaving(String percent) {
    return 'Birim fiyatı yaklaşık %$percent daha düşük.';
  }

  @override
  String get unitPriceSame => 'Birim fiyatları aynı; gerçekten kullanacağın boyu seç.';

  @override
  String get unitPieceLabel => 'adet';

  @override
  String fuelHeadline(String amount) {
    return 'Yolculuk yaklaşık $amount yakıt tutar.';
  }

  @override
  String yearlyHeadline(String amount) {
    return 'Bu, yılda $amount eder.';
  }

  @override
  String daysUntilHeadline(int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$days gün kaldı.', zero: 'Bugün!');
    return '$_temp0';
  }

  @override
  String optionN(int n) {
    return '$n. seçenek';
  }

  @override
  String get decideTitle => 'Karar ver';

  @override
  String get decideIntro => 'Seçeneklerini ve senin için önemli olanları ekle, ben tartayım.';

  @override
  String get decideAddOption => 'Seçenek ekle';

  @override
  String get decidePrice => 'Fiyat (isteğe bağlı)';

  @override
  String get decideWhatMatters => 'Senin için ne önemli?';

  @override
  String get critPrice => 'Fiyat';

  @override
  String get critQuality => 'Kalite';

  @override
  String get critFit => 'İhtiyacıma uygun';

  @override
  String get critLongTerm => 'Uzun vadeli değer';

  @override
  String get critRisk => 'Düşük risk';

  @override
  String get critCustomHint => 'Önemli olan başka bir şey';

  @override
  String get weight1 => 'Az önemli';

  @override
  String get weight2 => 'Önemli';

  @override
  String get weight3 => 'Çok önemli';

  @override
  String get decideRate => 'Her seçeneği puanla';

  @override
  String get decideRateHelp => '1 = kötü, 5 = harika. Fiyat girdiysen fiyat puanı otomatik hesaplanır.';

  @override
  String get decideShow => 'En iyisini göster';

  @override
  String get decideRecommended => 'Önerilen seçenek';

  @override
  String get decideWhy => 'Neden?';

  @override
  String decideStrength(String criterion) {
    return '$criterion açısından daha iyi';
  }

  @override
  String decideWeakness(String criterion) {
    return '$criterion açısından daha zayıf';
  }

  @override
  String get decideTooClose => 'Çok yakın; ikisi de mantıklı. En çok neye önem verdiğine göre seç.';

  @override
  String get decideSlight => 'Hafif bir üstünlük var, büyük değil.';

  @override
  String get decideClear => 'Önceliklerine göre açık ara önde.';

  @override
  String get decideDisclaimer => 'Senin puanlarına dayanır. Almadan önce güncel fiyat ve detayları kontrol et.';

  @override
  String get decideNeedTwo => 'En az iki seçenek ekle.';

  @override
  String decideScore(int score) {
    return '$score/100';
  }

  @override
  String get calcTitle => 'Hesap makinesi';

  @override
  String get calcError => 'İfadeyi kontrol et';

  @override
  String get exploreTitle => 'Keşfet';

  @override
  String get exploreSolve => 'Çöz';

  @override
  String get exploreLife => 'Takip';

  @override
  String get exploreMyDay => 'Günüm';

  @override
  String get exploreMyDayBody => 'Bugünün planı, bütçen ve hedeflerin';

  @override
  String get savedTitle => 'Kaydedilenler';

  @override
  String get savedEmptyTitle => 'Henüz kaydedilen yok';

  @override
  String get savedEmptyBody => 'Bir problem çöz ve burada saklamak için Kaydet’e dokun.';

  @override
  String get removed => 'Kaldırıldı';

  @override
  String get recipeHeadline => 'Elindekilerle bunları yapabilirsin';

  @override
  String recipeMissing(String items) {
    return 'Eksik: $items';
  }

  @override
  String get recipeHaveAll => 'Her şey elinde';

  @override
  String recipeMinutes(int minutes) {
    return '$minutes dk';
  }

  @override
  String get addMissingToList => 'Eksikleri alışveriş listesine ekle';

  @override
  String get addedToList => 'Alışveriş listene eklendi';

  @override
  String get recipeNoMatch => 'Bu malzemelerle eşleşen tarif bulamadım. Fikir için Lio’ya sor.';

  @override
  String get gTypeHint => 'Ya da sorununu yaz…';

  @override
  String get gAnswerHint => 'Cevabını yaz…';

  @override
  String get gRestart => 'Baştan başla';

  @override
  String get gMainMenu => 'Ana menü';

  @override
  String get gSomethingElse => 'Başka bir şey';

  @override
  String get gNotUnderstood => 'Bunu henüz yapamıyorum. Bir konu seç, adım adım yardımcı olayım.';

  @override
  String get gInvalidNumber => 'Bu bir sayı gibi görünmüyor, tekrar dener misin?';

  @override
  String get gMood => 'Moral';

  @override
  String get gRemind => 'Hatırlat';

  @override
  String get gRemindPrompt => 'Neyi hatırlatayım?';

  @override
  String get gMoneyPrompt => 'Neyi hesaplayalım?';

  @override
  String get gRunway => 'Param ay sonuna yeter mi?';

  @override
  String get gDiscount => 'İndirim hesapla';

  @override
  String get gSplit => 'Hesabı böl';

  @override
  String get gInstallment => 'Taksit mi peşin mi?';

  @override
  String get gUnitPrice => 'Hangisi daha ucuz?';

  @override
  String get gVat => 'KDV ekle';

  @override
  String get gRaise => 'Maaş zammı';

  @override
  String get gYearly => 'Aboneliklerin yıllık maliyeti';

  @override
  String get gCalcPrompt => 'Ne hesaplayalım?';

  @override
  String get gPercentOf => 'Bir sayının yüzdesi';

  @override
  String get gConvert => 'Birim çevir';

  @override
  String get gDaysUntil => 'Bir tarihe kaç gün var?';

  @override
  String get gFuel => 'Yol yakıt masrafı';

  @override
  String get gOpenCalculator => 'Hesap makinesini aç';

  @override
  String get qAmountLeft => 'Ne kadar paran kaldı?';

  @override
  String get qDaysLeft => 'Kaç gün yetmesi lazım?';

  @override
  String get qMonthEnd => 'Ay sonuna kadar';

  @override
  String get qPrice => 'Fiyatı ne kadar?';

  @override
  String get qDiscountPct => 'Yüzde kaç indirim?';

  @override
  String get qTotal => 'Hesap toplam ne kadar?';

  @override
  String get qPeople => 'Kaç kişisiniz?';

  @override
  String get qTip => 'Bahşiş bırakacak mısınız?';

  @override
  String get qNoTip => 'Bahşiş yok';

  @override
  String get qMonthly => 'Aylık taksit ne kadar?';

  @override
  String get qMonths => 'Kaç ay?';

  @override
  String get qCash => 'Peşin fiyatı ne? (bilmiyorsan atla)';

  @override
  String get qSize1 => '1. ürün: miktarı ne? (ör. 1 L, 500 g, 6 adet)';

  @override
  String get qPrice1 => 'Fiyatı ne kadar?';

  @override
  String get qSize2 => '2. ürün: miktarı ne?';

  @override
  String get qPrice2 => 'Onun fiyatı ne kadar?';

  @override
  String get qNeedUnit => 'Bir birim ekle: 1 L, 500 g ya da 6 adet gibi.';

  @override
  String get qVatRate => 'KDV oranı kaç?';

  @override
  String get qSalary => 'Şu anki tutar ne kadar?';

  @override
  String get qRaisePct => 'Yüzde kaç zam?';

  @override
  String get qSubs => 'Aylık tutarları virgülle yaz (ör. 99, 149)';

  @override
  String get qNumber => 'Hangi sayı?';

  @override
  String get qPercent => 'Yüzde kaç?';

  @override
  String get qConvert => 'Neyi çevireyim? (ör. 5 kg kaç lb)';

  @override
  String get qDate => 'Hangi tarih? (ör. 31 Aralık)';

  @override
  String get qKm => 'Yol kaç km?';

  @override
  String get qConsumption => 'Araç 100 km’de kaç litre yakıyor?';

  @override
  String get qFuelPrice => 'Yakıtın litresi kaç?';

  @override
  String get gConvertFail => 'Anlayamadım. “5 kg kaç lb” ya da “30 C kaç F” gibi yazabilir misin?';

  @override
  String get gDateFail => 'Tarihi anlayamadım. “31 Aralık” gibi yazabilir misin?';

  @override
  String get gDecidePrompt => 'Hadi karar verelim. Seçeneklerin neler?';

  @override
  String get qOptions => 'Seçeneklerini yaz (ör. pizza sushi)';

  @override
  String get gDecideCompare => 'Detaylı karşılaştır';

  @override
  String get gCoin => 'Yazı tura at';

  @override
  String get gRandomPick => 'Benim yerime seç';

  @override
  String get coinHeads => 'Yazı! 🪙';

  @override
  String get coinTails => 'Tura! 🪙';

  @override
  String randomPicked(String option) {
    return 'Seçimim: $option! 🎲';
  }

  @override
  String get gFoodPrompt => 'Yemek zamanı! Ne lazım?';

  @override
  String get gCookWithWhatIHave => 'Evdekilerle ne pişirsem?';

  @override
  String get qIngredients => 'Evde neler var? (ör. yumurta domates peynir)';

  @override
  String get gWhatToEat => 'Ne yesem?';

  @override
  String get gShoppingList => 'Alışveriş listem';

  @override
  String get gRecipes => 'Tarifler';

  @override
  String mealIdea(String meal, int minutes) {
    return '$meal nasıl olur? Yaklaşık $minutes dakikada hazır.';
  }

  @override
  String get gAnotherIdea => 'Başka öneri';

  @override
  String get gWritePrompt => 'Ne tür bir mesaj yazalım?';

  @override
  String get tplBirthday => 'Doğum günü kutlama';

  @override
  String get tplThanks => 'Teşekkür';

  @override
  String get tplApology => 'Özür';

  @override
  String get tplLate => 'Geç kalıyorum';

  @override
  String get tplLeave => 'İzin isteme';

  @override
  String get tplDecline => 'Kibarca hayır deme';

  @override
  String get tplCongrats => 'Tebrik';

  @override
  String get tplCondolence => 'Başsağlığı';

  @override
  String get tplPayment => 'Ödeme hatırlatma';

  @override
  String get tplComplaint => 'Şikâyet';

  @override
  String get tplJob => 'İş başvurusu';

  @override
  String get tplLandlord => 'Ev sahibine mesaj';

  @override
  String get qTone => 'Hangi tonda olsun?';

  @override
  String get toneWarm => 'Samimi';

  @override
  String get toneFormal => 'Resmi';

  @override
  String get toneShort => 'Kısa';

  @override
  String get fName => 'Kime yazıyoruz? (isim yaz ya da atla)';

  @override
  String get fCompany => 'Hangi firma?';

  @override
  String get fWhatThanks => 'Ne için teşekkür ediyorsun?';

  @override
  String get fWhatApology => 'Ne için özür diliyorsun?';

  @override
  String get fWhatLeave => 'İzin sebebin ne?';

  @override
  String get fWhatDecline => 'Neye hayır diyorsun?';

  @override
  String get fWhatCongrats => 'Neyi tebrik ediyorsun?';

  @override
  String get fWhatPayment => 'Hangi ödeme? (ör. 500 TL kira)';

  @override
  String get fWhatComplaint => 'Sorun ne?';

  @override
  String get fWhatJob => 'Hangi pozisyon?';

  @override
  String get fWhatLandlord => 'Sorun ne? (ör. kombi arızası)';

  @override
  String get fWhenLate => 'Ne zaman orada olursun? (ör. 15 dakika sonra)';

  @override
  String get fWhenLeave => 'Hangi gün(ler)? (ör. Cuma günü)';

  @override
  String get writeResult => 'İşte birkaç versiyon. Beğendiğini kopyala.';

  @override
  String get copy => 'Kopyala';

  @override
  String get copied => 'Kopyalandı';

  @override
  String get gOtherTone => 'Başka ton';

  @override
  String get gOtherMessage => 'Başka mesaj';

  @override
  String get gMoodPrompt => 'Şu an nasıl hissediyorsun?';

  @override
  String get mTired => 'Yorgunum';

  @override
  String get mStressed => 'Stresliyim';

  @override
  String get mUnmotivated => 'Motivasyonum yok';

  @override
  String get mCantSleep => 'Uyuyamıyorum';

  @override
  String get mLonely => 'Yalnız hissediyorum';

  @override
  String get mVeryBad => 'Çok kötüyüm';

  @override
  String get mTiredReply =>
      'Olur böyle günler. Şunları dene:\n• bir bardak su ve 10 dakikalık yürüyüş\n• tek bir küçük iş, sonra gerçek bir mola\n• bu akşam erken yat';

  @override
  String get mStressedReply =>
      'Bir dakika yavaşlayalım:\n• 4 saniye nefes al, 4 tut, 6’da ver; beş kez\n• bugün en önemli tek şeyi yaz\n• geri kalanı biraz bekleyebilir';

  @override
  String get mUnmotivatedReply =>
      'Motivasyon çoğu zaman başladıktan sonra gelir:\n• işin 2 dakikalık bir versiyonunu seç\n• 10 dakikalık sayaç kur ve sadece başla\n• sayaç çalınca kendini ödüllendir';

  @override
  String get mCantSleepReply =>
      'Bu gece için:\n• ekranı bırak, ışıkları kıs\n• odayı serin tut\n• 20 dakika uyuyamazsan kalk, sakin bir şey oku, sonra tekrar dene';

  @override
  String get mLonelyReply =>
      'Yalnızlık zor bir his ve bunu yaşayan tek kişi sen değilsin. Küçük bir adım iyi gelebilir: özlediğin birine mesaj at ya da biraz insanların olduğu bir yere git; bir kafe, park ya da kurs.';

  @override
  String get mVeryBadReply =>
      'Böyle hissettiğin için çok üzgünüm. Bunu tek başına taşımak zorunda değilsin; lütfen bugün güvendiğin biriyle konuş. Kendine zarar vermeyi düşünüyorsan ya da tehlikedeysen hemen 112’yi ara.';

  @override
  String get gInspire => 'İlham ver';

  @override
  String get gMyDayPrompt => 'Bugünle ilgili ne öğrenmek istersin?';

  @override
  String get gTodayPlan => 'Bugünkü planım';

  @override
  String get gSpendToday => 'Bugün ne kadar harcayabilirim?';

  @override
  String get gMyScore => 'Yaşam puanım';

  @override
  String get gOpenMyDay => 'Günüm’ü aç';

  @override
  String get pPrompt => 'Hadi gününü planlayalım! Bugün neler yapman gerekiyor? (ör. rapor yaz annemi ara spor)';

  @override
  String pAlready(String tasks) {
    return 'Bugün listende zaten şunlar var: $tasks. Plana ekleyeyim mi?';
  }

  @override
  String get pYes => 'Evet';

  @override
  String get pNo => 'Hayır';

  @override
  String get pImportant => 'Hangisi en önemli?';

  @override
  String get pAllSame => 'Hepsi eşit';

  @override
  String get pDuration => 'Her biri ortalama ne kadar sürer?';

  @override
  String pHours(int hours) {
    return '$hours saat';
  }

  @override
  String get pStart => 'Ne zaman başlayalım?';

  @override
  String get pNow => 'Şimdi';

  @override
  String get pTimeFail => 'Saati 09:30 gibi yaz.';

  @override
  String get pResult => 'İşte bugünkü planın:';

  @override
  String get pFixed => 'zaten planlı';

  @override
  String get pBreaks => 'Aralara 10 dakika nefes payı bıraktım.';

  @override
  String pDidntFit(String tasks) {
    return 'Bunlar bugüne sığmadı: $tasks';
  }

  @override
  String get pAddToDay => 'Günüme ekle';

  @override
  String get pAdded => 'Tamam! Planın hatırlatmalarıyla birlikte Plan ekranında.';

  @override
  String get pRedo => 'Yeniden planla';

  @override
  String get pOpenPlan => 'Plan’ı aç';

  @override
  String get pNothing => 'Planlanacak bir şey yok. En az bir iş yaz.';

  @override
  String get lioSuggestions => 'Lio’nun önerileri';

  @override
  String get lioAllGood => 'Bugün her şey yolunda görünüyor. Dikkat gereken bir şey olursa söylerim.';

  @override
  String get insightsTitle => 'Öneriler';

  @override
  String get insightsIntro =>
      'Paranı, planlarını, alışkanlıklarını, ruh halini ve günlüğünü inceledim. Göze çarpanlar bunlar.';

  @override
  String get gMySuggestions => 'Önerilerim';

  @override
  String advOverBudget(String amount) {
    return 'Bugünkü bütçeni $amount aştın. Yarını biraz hafif tutalım.';
  }

  @override
  String advBudgetTight(String amount) {
    return 'Bugün için sadece $amount kaldı. Harcamasız bir akşam iyi gelir.';
  }

  @override
  String advSavingsOff(String amount) {
    return 'Bu hızla bu ay birikim hedefini yaklaşık $amount kaçıracaksın.';
  }

  @override
  String get advSetUpBudget =>
      'Birkaç harcama girdin. Aylık gelirini eklersen sana güvenli bir günlük limit hesaplarım.';

  @override
  String advWeeklyUp(int percent) {
    return 'Bu hafta her zamankinden %$percent fazla harcadın.';
  }

  @override
  String advWeeklyDown(int percent) {
    return 'Harika! Bu hafta her zamankinden %$percent az harcadın.';
  }

  @override
  String advCategorySpike(String category, int percent) {
    return '$category harcaman geçen aya göre %$percent arttı.';
  }

  @override
  String advSubscriptions(int count, String names, String amount) {
    return '$count abonelik görünüyor ($names): yılda yaklaşık $amount. Hepsini kullanıyor musun?';
  }

  @override
  String advTopCategory(String category, int percent) {
    return 'Bu ay harcamalarının %$percent kadarı $category.';
  }

  @override
  String advOverdue(int count) {
    return '$count gecikmiş işin var. Bugüne yerleştirelim mi?';
  }

  @override
  String get advNoPlan => 'Bugün için henüz plan yok. Benimle 2 dakika, günün şekillensin.';

  @override
  String advUnscheduled(int count) {
    return 'Bugünkü $count işin henüz saati yok. Saatlerini ayarlayalım mı?';
  }

  @override
  String advTasksGood(int count) {
    return 'Bu hafta $count iş bitirdin, harika gidiyorsun!';
  }

  @override
  String advHabitRisk(int count, String name) {
    return '$count günlük $name serin bugün seni bekliyor.';
  }

  @override
  String advHabitDown(int percent) {
    return 'Alışkanlıkların bu hafta $percent puan düştü. Bugün için küçük bir hedef seç.';
  }

  @override
  String advHabitUp(int percent) {
    return 'Alışkanlıkların bu hafta $percent puan arttı. Böyle devam!';
  }

  @override
  String get advMoodDown => 'Bu hafta ruh halin biraz düşük. Konuşmak ya da birkaç satır yazmak ister misin?';

  @override
  String get advMoodSleep => 'Az uyuduğun günlerde ruh halin daha düşük oluyor. Erken yatmak iyi gelebilir.';

  @override
  String get advJournalNudge => 'Bugün nasıl geçti? Günlüğüne iki satır yeter.';

  @override
  String advJournalStreak(int count) {
    return '$count gündür günlük yazıyorsun. Çok güzel bir alışkanlık.';
  }

  @override
  String advShopping(int count) {
    return 'Alışveriş listende $count ürün bekliyor.';
  }

  @override
  String advCook(String name, int minutes) {
    return '$name için her şey elinde ($minutes dk).';
  }

  @override
  String get actOpenMoney => 'Para’yı aç';

  @override
  String get actPlanDay => 'Günümü planla';

  @override
  String get actOpenPlan => 'Plan’ı aç';

  @override
  String get actOpenHabits => 'Alışkanlıklar';

  @override
  String get actTalk => 'Lio ile konuş';

  @override
  String get actLogMood => 'Uyku ve ruh hali';

  @override
  String get actWrite => 'Yaz';

  @override
  String get actShopping => 'Listeyi aç';

  @override
  String get actRecipe => 'Tarife bak';

  @override
  String get quickJournal => 'Günlük';

  @override
  String journalStreakLabel(int count) {
    return '$count günlük seri';
  }

  @override
  String journalThisMonth(int count) {
    return 'Bu ay $count';
  }

  @override
  String get journalMoodWeek => 'Bu haftaki ruh hali';

  @override
  String get journalSearch => 'Günlüğünde ara';

  @override
  String get journalTodayPrompt => 'Bugünün sorusu';

  @override
  String get journalHowFeel => 'Nasıl hissediyorsun?';

  @override
  String journalWords(int count) {
    return '$count kelime';
  }

  @override
  String get journalNoResults => 'Eşleşen yazı yok.';

  @override
  String get journalWriteToday => 'Bugünü yaz';

  @override
  String get journalSaved => 'Günlüğüne kaydedildi';

  @override
  String get jp1 => 'Bugün seni ne gülümsetti?';

  @override
  String get jp2 => 'Neye minnettarsın?';

  @override
  String get jp3 => 'Bugün enerjini ne düşürdü?';

  @override
  String get jp4 => 'Yarın neyi farklı yapacaksın?';

  @override
  String get jp5 => 'Bugün öğrendiğin bir şey';

  @override
  String get jp6 => 'Gününü kim güzelleştirdi?';

  @override
  String get jp7 => 'Neyi dört gözle bekliyorsun?';
}
