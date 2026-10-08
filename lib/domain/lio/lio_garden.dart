import '../../core/utils/dates.dart';

/// A postcard Lio brings back from a trip: a real place and one fact.
class Postcard {
  const Postcard(this.id, this.placeTr, this.placeEn, this.factTr, this.factEn);
  final String id;
  final String placeTr, placeEn, factTr, factEn;

  String place(bool tr) => tr ? placeTr : placeEn;
  String fact(bool tr) => tr ? factTr : factEn;
}

const postcards = <Postcard>[
  Postcard(
    'kapadokya',
    'Kapadokya',
    'Cappadocia',
    'Peri bacaları milyonlarca yıl önce volkanik küllerden oluştu.',
    'The fairy chimneys formed from volcanic ash millions of years ago.',
  ),
  Postcard(
    'pamukkale',
    'Pamukkale',
    'Pamukkale',
    'Beyaz travertenler, kireçli sıcak suyun binlerce yıl akmasıyla oluştu.',
    'The white terraces were built by warm, mineral-rich water over thousands of years.',
  ),
  Postcard(
    'efes',
    'Efes',
    'Ephesus',
    'Celsus Kütüphanesi bir zamanlar 12.000 parşömene ev sahipliği yaptı.',
    'The Library of Celsus once held about 12,000 scrolls.',
  ),
  Postcard(
    'nemrut',
    'Nemrut Dağı',
    'Mount Nemrut',
    'Zirvedeki dev heykellerde gün doğumu ayrı bir güzel.',
    'Sunrise over the giant stone heads at the summit is famous.',
  ),
  Postcard(
    'sumela',
    'Sümela Manastırı',
    'Sumela Monastery',
    'Sarp bir kayalığa, denizden 1.200 metre yükseğe kurulmuş.',
    'It clings to a cliff about 1,200 metres above sea level.',
  ),
  Postcard(
    'uzungol',
    'Uzungöl',
    'Uzungöl',
    'Göl, dağdan düşen kayaların dereyi kapatmasıyla oluştu.',
    'The lake formed when a landslide dammed a mountain stream.',
  ),
  Postcard(
    'galata',
    'Galata Kulesi',
    'Galata Tower',
    'Hezarfen Ahmed Çelebi\'nin buradan uçtuğu anlatılır.',
    'Legend says Hezârfen Ahmed Çelebi flew from here across the Bosphorus.',
  ),
  Postcard(
    'ayasofya',
    'Ayasofya',
    'Hagia Sophia',
    'Kubbesi yaklaşık bin yıl dünyanın en büyük kubbesiydi.',
    'Its dome was the largest in the world for nearly a thousand years.',
  ),
  Postcard(
    'olimpos',
    'Olimpos',
    'Olympos',
    'Yakındaki Yanartaş\'ta binlerce yıldır sönmeyen alevler yanar.',
    'Nearby Chimaera has flames that have burned for thousands of years.',
  ),
  Postcard(
    'kas',
    'Kaş',
    'Kaş',
    'Batık Kekova şehrinin kalıntıları berrak suyun altından görünür.',
    'The ruins of sunken Kekova can be seen through the clear water.',
  ),
  Postcard(
    'safranbolu',
    'Safranbolu',
    'Safranbolu',
    'Adını bir zamanlar burada yetiştirilen safrandan alır.',
    'It takes its name from the saffron once grown here.',
  ),
  Postcard(
    'mardin',
    'Mardin',
    'Mardin',
    'Taş evler, Mezopotamya ovasına bakan bir yamaca basamak basamak dizilir.',
    'Stone houses step down a hill overlooking the Mesopotamian plain.',
  ),
  Postcard(
    'ani',
    'Ani Harabeleri',
    'Ani',
    '"Bin bir kilise şehri" olarak bilinirdi.',
    'It was known as the "city of 1,001 churches".',
  ),
  Postcard(
    'gobekli',
    'Göbeklitepe',
    'Göbekli Tepe',
    'Yaklaşık 11.000 yıllık; Stonehenge\'den 6.000 yıl daha eski.',
    'About 11,000 years old, some 6,000 years older than Stonehenge.',
  ),
  Postcard(
    'abant',
    'Abant Gölü',
    'Lake Abant',
    'Sonbaharda çevresindeki ormanlar sarı ve kırmızıya döner.',
    'In autumn the forests around it turn gold and red.',
  ),
  Postcard(
    'bozcaada',
    'Bozcaada',
    'Bozcaada',
    'Rüzgârı ve bağlarıyla ünlü küçük bir Ege adası.',
    'A small Aegean island known for its wind and vineyards.',
  ),
  Postcard(
    'ayder',
    'Ayder Yaylası',
    'Ayder Plateau',
    'Bulutların arasında, kaplıcası olan bir yayla.',
    'A highland meadow above the clouds, with hot springs.',
  ),
  Postcard(
    'cunda',
    'Cunda',
    'Cunda Island',
    'Taş evleri ve zeytinlikleriyle Ayvalık\'ın karşısında.',
    'Stone houses and olive groves across from Ayvalık.',
  ),
  Postcard(
    'zeugma',
    'Zeugma',
    'Zeugma',
    'Çingene Kızı mozaiği buradan çıkarıldı.',
    'The famous "Gypsy Girl" mosaic was found here.',
  ),
  Postcard(
    'ishak',
    'İshak Paşa Sarayı',
    'Ishak Pasha Palace',
    'Ağrı Dağı\'na bakan sarayda yüzyıllar önce merkezi ısıtma vardı.',
    'Facing Mount Ararat, it had central heating centuries ago.',
  ),
  Postcard(
    'salda',
    'Salda Gölü',
    'Lake Salda',
    'Beyaz kumsalı ve turkuaz suyuyla "Türkiye\'nin Maldivleri" denir.',
    'Its white shores and turquoise water earned it the name "Turkey\'s Maldives".',
  ),
  Postcard(
    'amasra',
    'Amasra',
    'Amasra',
    'Karadeniz\'e uzanan kalesi ve iki limanıyla ünlü.',
    'Known for its castle and twin harbours on the Black Sea.',
  ),
  Postcard(
    'patara',
    'Patara',
    'Patara',
    'Türkiye\'nin en uzun kumsallarından biri; caretta carettalar burada yumurtlar.',
    'One of Turkey\'s longest beaches, where loggerhead turtles nest.',
  ),
  Postcard(
    'van',
    'Van Gölü',
    'Lake Van',
    'Türkiye\'nin en büyük gölü; suyu sodalı olduğu için sabun gibi köpürür.',
    'Turkey\'s largest lake; its soda-rich water foams like soap.',
  ),
];

/// Lio's day: small things you finish give him energy; at [goal] he goes
/// exploring and comes back [tripLength] later with a postcard.
enum GardenPhase { charging, exploring, giftWaiting, opened }

class GardenState {
  const GardenState({required this.energy, required this.phase, this.backAt});
  final int energy;
  final GardenPhase phase;

  /// When Lio comes back (while exploring).
  final DateTime? backAt;
}

abstract final class LioGarden {
  static const goal = 3;
  static const tripLength = Duration(hours: 2);

  /// Where the day stands. [tripStart] is when Lio left today (if he did),
  /// [openedToday] whether today's gift was opened.
  static GardenState state({
    required int energy,
    required DateTime now,
    required DateTime? tripStart,
    required bool openedToday,
  }) {
    final e = energy.clamp(0, goal);
    final trip = tripStart != null && Dates.sameDay(tripStart, now) ? tripStart : null;
    if (openedToday) return GardenState(energy: e, phase: GardenPhase.opened);
    if (trip == null) return GardenState(energy: e, phase: GardenPhase.charging);
    final back = trip.add(tripLength);
    return now.isBefore(back)
        ? GardenState(energy: e, phase: GardenPhase.exploring, backAt: back)
        : GardenState(energy: e, phase: GardenPhase.giftWaiting, backAt: back);
  }

  /// Today's postcard: one not collected yet (stable for the day), or any.
  static Postcard pick(DateTime day, Set<String> collected, {int salt = 0}) {
    final fresh = postcards.where((p) => !collected.contains(p.id)).toList();
    final pool = fresh.isEmpty ? postcards : fresh;
    final seed = (day.year * 372 + day.month * 31 + day.day + salt * 7919).abs();
    return pool[seed % pool.length];
  }
}
