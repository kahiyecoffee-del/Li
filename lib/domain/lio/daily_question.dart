import '../../core/utils/dates.dart';

/// One general-knowledge question. The right answer is the first option in
/// the data; [DailyQuestion.forDay] shuffles them for display.
class QuizItem {
  const QuizItem(this.en, this.tr, this.optionsEn, [this.optionsTr]);

  final String en;
  final String tr;
  final List<String> optionsEn;

  /// Null when the options read the same in both languages (names, numbers).
  final List<String>? optionsTr;

  String question(String lang) => lang == 'tr' ? tr : en;
  List<String> options(String lang) => lang == 'tr' ? (optionsTr ?? optionsEn) : optionsEn;
}

/// Today's question with its options in a stable, shuffled order.
class DailyQuestion {
  const DailyQuestion(this.index, this.item, this.order, this.correct);

  final int index;
  final QuizItem item;

  /// Display order: positions into the item's options.
  final List<int> order;

  /// Display index of the right answer.
  final int correct;

  String question(String lang) => item.question(lang);
  List<String> options(String lang) => [for (final i in order) item.options(lang)[i]];

  /// Two wrong answers to hide for the hint (display indexes).
  List<int> get hintHides => [
    for (var i = 0; i < order.length; i++)
      if (i != correct) i,
  ].take(2).toList();

  /// The same question for everyone on a day, cycling through the bank in
  /// a scrambled but fixed order.
  static DailyQuestion forDay(DateTime day) {
    final n = quizBank.length;
    final dayNo = DateTime.utc(day.year, day.month, day.day).difference(DateTime.utc(2024)).inDays;
    // 37 is coprime with the bank size, so every question comes once per cycle.
    final index = (dayNo * 37) % n;
    final item = quizBank[index];
    final count = item.optionsEn.length;
    final shift = dayNo % count;
    final order = [for (var i = 0; i < count; i++) (i + shift) % count];
    return DailyQuestion(index, item, order, order.indexOf(0));
  }
}

/// Progress kept on the device.
class QuizProgress {
  const QuizProgress({this.answeredDay, this.answer, this.streak = 0, this.correctTotal = 0, this.lastCorrectDay});

  /// `yyyy-MM-dd` of the last answered day and the display index picked.
  final String? answeredDay;
  final int? answer;

  /// Days in a row answered right.
  final int streak;
  final int correctTotal;
  final String? lastCorrectDay;

  bool answeredOn(DateTime day) => answeredDay == Dates.dayKey(day);

  /// The streak as of [day] (broken when yesterday was missed).
  int streakOn(DateTime day) {
    final last = lastCorrectDay;
    if (last == null) return 0;
    final today = Dates.dayKey(day);
    final yesterday = Dates.dayKey(Dates.addDays(Dates.dateOnly(day), -1));
    return last == today || last == yesterday ? streak : 0;
  }

  QuizProgress answerOn(DateTime day, int pick, {required bool right}) {
    final key = Dates.dayKey(day);
    if (answeredDay == key) return this;
    return QuizProgress(
      answeredDay: key,
      answer: pick,
      streak: right ? streakOn(day) + 1 : 0,
      correctTotal: correctTotal + (right ? 1 : 0),
      lastCorrectDay: right ? key : lastCorrectDay,
    );
  }
}

const quizBank = <QuizItem>[
  QuizItem(
    'What is the largest planet in the Solar System?',
    'Güneş Sistemi’nin en büyük gezegeni hangisi?',
    ['Jupiter', 'Saturn', 'Neptune', 'Earth'],
    ['Jüpiter', 'Satürn', 'Neptün', 'Dünya'],
  ),
  QuizItem('How many continents are there?', 'Dünyada kaç kıta var?', ['7', '5', '6', '8']),
  QuizItem(
    'Which gas do plants take in for photosynthesis?',
    'Bitkiler fotosentez için hangi gazı alır?',
    ['Carbon dioxide', 'Oxygen', 'Nitrogen', 'Helium'],
    ['Karbondioksit', 'Oksijen', 'Azot', 'Helyum'],
  ),
  QuizItem('Who painted the Mona Lisa?', 'Mona Lisa’yı kim yaptı?', [
    'Leonardo da Vinci',
    'Michelangelo',
    'Raphael',
    'Rembrandt',
  ]),
  QuizItem('What is the chemical symbol for gold?', 'Altının kimyasal sembolü nedir?', ['Au', 'Ag', 'Go', 'Gd']),
  QuizItem('How many bones are in the adult human body?', 'Yetişkin bir insanda kaç kemik vardır?', [
    '206',
    '186',
    '226',
    '306',
  ]),
  QuizItem(
    'Which is the longest river in Africa?',
    'Afrika’nın en uzun nehri hangisi?',
    ['Nile', 'Congo', 'Niger', 'Zambezi'],
    ['Nil', 'Kongo', 'Nijer', 'Zambezi'],
  ),
  QuizItem('What is the capital of Japan?', 'Japonya’nın başkenti neresi?', ['Tokyo', 'Kyoto', 'Osaka', 'Hiroshima']),
  QuizItem(
    'Which ocean is the largest?',
    'En büyük okyanus hangisi?',
    ['Pacific', 'Atlantic', 'Indian', 'Arctic'],
    ['Büyük Okyanus (Pasifik)', 'Atlas Okyanusu', 'Hint Okyanusu', 'Arktik Okyanusu'],
  ),
  QuizItem('How many sides does a hexagon have?', 'Altıgenin kaç kenarı vardır?', ['6', '5', '7', '8']),
  QuizItem(
    'Which planet is known as the Red Planet?',
    'Kızıl Gezegen olarak bilinen hangisi?',
    ['Mars', 'Venus', 'Mercury', 'Jupiter'],
    ['Mars', 'Venüs', 'Merkür', 'Jüpiter'],
  ),
  QuizItem('Who wrote "Romeo and Juliet"?', '"Romeo ve Juliet"i kim yazdı?', [
    'William Shakespeare',
    'Charles Dickens',
    'Jane Austen',
    'Mark Twain',
  ]),
  QuizItem('What is the boiling point of water at sea level in °C?', 'Deniz seviyesinde su kaç °C’de kaynar?', [
    '100',
    '90',
    '110',
    '120',
  ]),
  QuizItem(
    'Which country gave the Statue of Liberty to the USA?',
    'Özgürlük Heykeli’ni ABD’ye hangi ülke hediye etti?',
    ['France', 'United Kingdom', 'Spain', 'Italy'],
    ['Fransa', 'Birleşik Krallık', 'İspanya', 'İtalya'],
  ),
  QuizItem(
    'What is the hardest natural substance?',
    'Doğadaki en sert madde hangisi?',
    ['Diamond', 'Iron', 'Quartz', 'Granite'],
    ['Elmas', 'Demir', 'Kuvars', 'Granit'],
  ),
  QuizItem(
    'How many minutes are in a day?',
    'Bir günde kaç dakika vardır?',
    ['1,440', '1,240', '1,400', '1,600'],
    ['1.440', '1.240', '1.400', '1.600'],
  ),
  QuizItem('Which is the smallest prime number?', 'En küçük asal sayı hangisi?', ['2', '1', '3', '0']),
  QuizItem(
    'In which city is the Colosseum?',
    'Kolezyum hangi şehirde?',
    ['Rome', 'Athens', 'Istanbul', 'Paris'],
    ['Roma', 'Atina', 'İstanbul', 'Paris'],
  ),
  QuizItem(
    'What do bees make?',
    'Arılar ne üretir?',
    ['Honey', 'Silk', 'Milk', 'Wax paper'],
    ['Bal', 'İpek', 'Süt', 'Kâğıt'],
  ),
  QuizItem(
    'Which instrument has 88 keys?',
    'Hangi çalgının 88 tuşu vardır?',
    ['Piano', 'Guitar', 'Violin', 'Flute'],
    ['Piyano', 'Gitar', 'Keman', 'Flüt'],
  ),
  QuizItem('What is the capital of Australia?', 'Avustralya’nın başkenti neresi?', [
    'Canberra',
    'Sydney',
    'Melbourne',
    'Perth',
  ]),
  QuizItem(
    'Which vitamin does sunlight help the body make?',
    'Güneş ışığı vücudun hangi vitamini üretmesine yardım eder?',
    ['Vitamin D', 'Vitamin C', 'Vitamin A', 'Vitamin K'],
    ['D vitamini', 'C vitamini', 'A vitamini', 'K vitamini'],
  ),
  QuizItem(
    'How many players does a football (soccer) team have on the field?',
    'Bir futbol takımı sahada kaç oyuncuyla oynar?',
    ['11', '10', '9', '12'],
  ),
  QuizItem(
    'What is the largest mammal?',
    'En büyük memeli hangisi?',
    ['Blue whale', 'Elephant', 'Giraffe', 'Hippopotamus'],
    ['Mavi balina', 'Fil', 'Zürafa', 'Su aygırı'],
  ),
  QuizItem(
    'Which language has the most native speakers?',
    'Ana dili olarak en çok konuşulan dil hangisi?',
    ['Mandarin Chinese', 'English', 'Spanish', 'Hindi'],
    ['Çince (Mandarin)', 'İngilizce', 'İspanyolca', 'Hintçe'],
  ),
  QuizItem('What is the freezing point of water in °F?', 'Su kaç °F’de donar?', ['32', '0', '10', '50']),
  QuizItem('Who developed the theory of relativity?', 'Görelilik kuramını kim geliştirdi?', [
    'Albert Einstein',
    'Isaac Newton',
    'Galileo Galilei',
    'Nikola Tesla',
  ]),
  QuizItem('Which is the tallest mountain above sea level?', 'Deniz seviyesinden en yüksek dağ hangisi?', [
    'Everest',
    'K2',
    'Kilimanjaro',
    'Mont Blanc',
  ]),
  QuizItem('How many hours are in a week?', 'Bir haftada kaç saat vardır?', ['168', '144', '172', '160']),
  QuizItem(
    'Which organ pumps blood through the body?',
    'Kanı vücuda hangi organ pompalar?',
    ['Heart', 'Lungs', 'Liver', 'Kidneys'],
    ['Kalp', 'Akciğerler', 'Karaciğer', 'Böbrekler'],
  ),
  QuizItem('What is the capital of Canada?', 'Kanada’nın başkenti neresi?', [
    'Ottawa',
    'Toronto',
    'Vancouver',
    'Montreal',
  ]),
  QuizItem(
    'Which metal is liquid at room temperature?',
    'Oda sıcaklığında sıvı olan metal hangisi?',
    ['Mercury', 'Lead', 'Aluminium', 'Tin'],
    ['Cıva', 'Kurşun', 'Alüminyum', 'Kalay'],
  ),
  QuizItem('How many strings does a standard guitar have?', 'Standart bir gitarın kaç teli vardır?', [
    '6',
    '4',
    '5',
    '7',
  ]),
  QuizItem(
    'Which country is home to the kangaroo?',
    'Kanguru hangi ülkenin simgesidir?',
    ['Australia', 'South Africa', 'Brazil', 'India'],
    ['Avustralya', 'Güney Afrika', 'Brezilya', 'Hindistan'],
  ),
  QuizItem('What is 15% of 200?', '200’ün %15’i kaçtır?', ['30', '15', '25', '35']),
  QuizItem(
    'Which is the largest desert in the world (hot or cold)?',
    'Dünyanın en büyük çölü hangisi (sıcak ya da soğuk)?',
    ['Antarctica', 'Sahara', 'Gobi', 'Arabian'],
    ['Antarktika', 'Büyük Sahra', 'Gobi', 'Arabistan Çölü'],
  ),
  QuizItem('Who was the first person to walk on the Moon?', 'Ay’da yürüyen ilk insan kim?', [
    'Neil Armstrong',
    'Buzz Aldrin',
    'Yuri Gagarin',
    'Michael Collins',
  ]),
  QuizItem('How many colours are in a rainbow?', 'Gökkuşağında kaç renk vardır?', ['7', '6', '5', '8']),
  QuizItem(
    'What is the main ingredient of guacamole?',
    'Guacamole’nin ana malzemesi nedir?',
    ['Avocado', 'Tomato', 'Pepper', 'Onion'],
    ['Avokado', 'Domates', 'Biber', 'Soğan'],
  ),
  QuizItem(
    'Which planet is closest to the Sun?',
    'Güneş’e en yakın gezegen hangisi?',
    ['Mercury', 'Venus', 'Mars', 'Earth'],
    ['Merkür', 'Venüs', 'Mars', 'Dünya'],
  ),
  QuizItem('What is the capital of Brazil?', 'Brezilya’nın başkenti neresi?', [
    'Brasília',
    'Rio de Janeiro',
    'São Paulo',
    'Salvador',
  ]),
  QuizItem(
    'Which blood type is the universal donor?',
    'Genel verici kan grubu hangisi?',
    ['O negative', 'AB positive', 'A positive', 'B negative'],
    ['0 Rh negatif', 'AB Rh pozitif', 'A Rh pozitif', 'B Rh negatif'],
  ),
  QuizItem('How many days does a leap year have?', 'Artık yıl kaç gündür?', ['366', '365', '364', '367']),
  QuizItem(
    'In which country are the pyramids of Giza?',
    'Gize piramitleri hangi ülkede?',
    ['Egypt', 'Mexico', 'Peru', 'Sudan'],
    ['Mısır', 'Meksika', 'Peru', 'Sudan'],
  ),
  QuizItem(
    'Which is the fastest land animal?',
    'Karadaki en hızlı hayvan hangisi?',
    ['Cheetah', 'Lion', 'Horse', 'Pronghorn'],
    ['Çita', 'Aslan', 'At', 'Çatalboynuzlu antilop'],
  ),
  QuizItem(
    'What is H2O better known as?',
    'H2O’nun yaygın adı nedir?',
    ['Water', 'Salt', 'Hydrogen peroxide', 'Ozone'],
    ['Su', 'Tuz', 'Hidrojen peroksit', 'Ozon'],
  ),
  QuizItem(
    'Which country has the most time zones (including territories)?',
    'Toprakları dahil en çok saat dilimine sahip ülke hangisi?',
    ['France', 'Russia', 'USA', 'China'],
    ['Fransa', 'Rusya', 'ABD', 'Çin'],
  ),
  QuizItem('How many teeth does an adult usually have?', 'Bir yetişkinin genellikle kaç dişi vardır?', [
    '32',
    '28',
    '30',
    '36',
  ]),
  QuizItem('Which city is known as the Big Apple?', '"Büyük Elma" diye bilinen şehir hangisi?', [
    'New York',
    'Los Angeles',
    'Chicago',
    'London',
  ]),
  QuizItem('What is the square root of 144?', '144’ün karekökü kaçtır?', ['12', '14', '11', '16']),
  QuizItem('Who invented the telephone (first US patent)?', 'Telefonun ilk ABD patentini kim aldı?', [
    'Alexander Graham Bell',
    'Thomas Edison',
    'Nikola Tesla',
    'Guglielmo Marconi',
  ]),
  QuizItem(
    'Which is the largest country by area?',
    'Yüzölçümü en büyük ülke hangisi?',
    ['Russia', 'Canada', 'China', 'USA'],
    ['Rusya', 'Kanada', 'Çin', 'ABD'],
  ),
  QuizItem('What is the currency of Japan?', 'Japonya’nın para birimi nedir?', ['Yen', 'Won', 'Yuan', 'Ringgit']),
  QuizItem('How many legs does a spider have?', 'Örümceğin kaç bacağı vardır?', ['8', '6', '10', '12']),
  QuizItem(
    'Which sense is linked to the olfactory system?',
    'Koku sistemi hangi duyuyla ilgilidir?',
    ['Smell', 'Taste', 'Hearing', 'Touch'],
    ['Koku', 'Tat', 'İşitme', 'Dokunma'],
  ),
  QuizItem(
    'Which is the closest star to Earth?',
    'Dünya’ya en yakın yıldız hangisi?',
    ['The Sun', 'Proxima Centauri', 'Sirius', 'Polaris'],
    ['Güneş', 'Proxima Centauri', 'Sirius', 'Kutup Yıldızı'],
  ),
  QuizItem(
    'What is the capital of Turkey?',
    'Türkiye’nin başkenti neresi?',
    ['Ankara', 'Istanbul', 'Izmir', 'Bursa'],
    ['Ankara', 'İstanbul', 'İzmir', 'Bursa'],
  ),
  QuizItem('Which composer wrote the "Moonlight Sonata"?', '"Ay Işığı Sonatı"nı hangi besteci yazdı?', [
    'Beethoven',
    'Mozart',
    'Bach',
    'Chopin',
  ]),
  QuizItem(
    'How many grams are in a kilogram?',
    'Bir kilogramda kaç gram vardır?',
    ['1,000', '100', '10,000', '500'],
    ['1.000', '100', '10.000', '500'],
  ),
  QuizItem(
    'Which part of the plant makes most of its food?',
    'Bitkinin besinini çoğunlukla hangi kısmı üretir?',
    ['Leaves', 'Roots', 'Stem', 'Flowers'],
    ['Yapraklar', 'Kökler', 'Gövde', 'Çiçekler'],
  ),
  QuizItem(
    'What is the capital of Egypt?',
    'Mısır’ın başkenti neresi?',
    ['Cairo', 'Alexandria', 'Giza', 'Luxor'],
    ['Kahire', 'İskenderiye', 'Gize', 'Luksor'],
  ),
  QuizItem(
    'Which shape has three sides?',
    'Üç kenarı olan şekil hangisi?',
    ['Triangle', 'Square', 'Pentagon', 'Circle'],
    ['Üçgen', 'Kare', 'Beşgen', 'Daire'],
  ),
  QuizItem(
    'Which bird is a symbol of peace?',
    'Barışın simgesi olan kuş hangisi?',
    ['Dove', 'Eagle', 'Owl', 'Swan'],
    ['Güvercin', 'Kartal', 'Baykuş', 'Kuğu'],
  ),
  QuizItem('In which year did the Berlin Wall fall?', 'Berlin Duvarı hangi yıl yıkıldı?', [
    '1989',
    '1991',
    '1985',
    '1979',
  ]),
  QuizItem(
    'What is the largest organ of the human body?',
    'İnsan vücudunun en büyük organı hangisi?',
    ['Skin', 'Liver', 'Brain', 'Lungs'],
    ['Deri', 'Karaciğer', 'Beyin', 'Akciğerler'],
  ),
  QuizItem(
    'Which country invented paper?',
    'Kâğıdı hangi ülke icat etti?',
    ['China', 'Egypt', 'Greece', 'India'],
    ['Çin', 'Mısır', 'Yunanistan', 'Hindistan'],
  ),
  QuizItem('How many zeros are in one million?', 'Bir milyonda kaç sıfır vardır?', ['6', '5', '7', '9']),
  QuizItem(
    'Which is the main language of Brazil?',
    'Brezilya’nın ana dili hangisi?',
    ['Portuguese', 'Spanish', 'English', 'French'],
    ['Portekizce', 'İspanyolca', 'İngilizce', 'Fransızca'],
  ),
  QuizItem(
    'What do caterpillars turn into?',
    'Tırtıllar neye dönüşür?',
    ['Butterflies or moths', 'Beetles', 'Bees', 'Dragonflies'],
    ['Kelebek ya da güve', 'Böcek', 'Arı', 'Yusufçuk'],
  ),
  QuizItem(
    'Which city hosted the first modern Olympic Games (1896)?',
    'İlk modern Olimpiyat Oyunları (1896) hangi şehirde yapıldı?',
    ['Athens', 'Paris', 'London', 'Rome'],
    ['Atina', 'Paris', 'Londra', 'Roma'],
  ),
  QuizItem(
    'What is the most abundant gas in Earth’s air?',
    'Dünya havasında en çok bulunan gaz hangisi?',
    ['Nitrogen', 'Oxygen', 'Carbon dioxide', 'Argon'],
    ['Azot', 'Oksijen', 'Karbondioksit', 'Argon'],
  ),
  QuizItem('How many weeks are in a year?', 'Bir yılda kaç hafta vardır?', ['52', '48', '50', '54']),
  QuizItem(
    'Which famous scientist proposed the laws of motion and gravity?',
    'Hareket ve kütle çekim yasalarını kim ortaya koydu?',
    ['Isaac Newton', 'Albert Einstein', 'Galileo Galilei', 'Johannes Kepler'],
  ),
  QuizItem(
    'What is the capital of Spain?',
    'İspanya’nın başkenti neresi?',
    ['Madrid', 'Barcelona', 'Seville', 'Valencia'],
    ['Madrid', 'Barselona', 'Sevilla', 'Valensiya'],
  ),
  QuizItem(
    'Which nut is used to make marzipan?',
    'Badem ezmesi (marzipan) hangi kuruyemişten yapılır?',
    ['Almond', 'Hazelnut', 'Walnut', 'Peanut'],
    ['Badem', 'Fındık', 'Ceviz', 'Yer fıstığı'],
  ),
  QuizItem(
    'What is the largest bone in the human body?',
    'İnsan vücudundaki en uzun kemik hangisi?',
    ['Femur', 'Tibia', 'Humerus', 'Spine'],
    ['Uyluk kemiği', 'Kaval kemiği', 'Pazı kemiği', 'Omurga'],
  ),
  QuizItem(
    'Which planet has the most famous rings?',
    'En meşhur halkalara sahip gezegen hangisi?',
    ['Saturn', 'Uranus', 'Jupiter', 'Neptune'],
    ['Satürn', 'Uranüs', 'Jüpiter', 'Neptün'],
  ),
  QuizItem('How many degrees are in a right angle?', 'Dik açı kaç derecedir?', ['90', '45', '180', '60']),
  QuizItem(
    'Which country is shaped like a boot?',
    'Hangi ülke çizme şeklindedir?',
    ['Italy', 'Greece', 'Chile', 'Portugal'],
    ['İtalya', 'Yunanistan', 'Şili', 'Portekiz'],
  ),
  QuizItem(
    'What is the main language spoken in Mexico?',
    'Meksika’da en çok konuşulan dil hangisi?',
    ['Spanish', 'Portuguese', 'English', 'French'],
    ['İspanyolca', 'Portekizce', 'İngilizce', 'Fransızca'],
  ),
  QuizItem(
    'Which animal is known as the "ship of the desert"?',
    '"Çölün gemisi" diye bilinen hayvan hangisi?',
    ['Camel', 'Horse', 'Donkey', 'Elephant'],
    ['Deve', 'At', 'Eşek', 'Fil'],
  ),
  QuizItem(
    'What is the capital of Germany?',
    'Almanya’nın başkenti neresi?',
    ['Berlin', 'Munich', 'Hamburg', 'Frankfurt'],
    ['Berlin', 'Münih', 'Hamburg', 'Frankfurt'],
  ),
  QuizItem(
    'How many seconds are in an hour?',
    'Bir saatte kaç saniye vardır?',
    ['3,600', '360', '6,000', '1,800'],
    ['3.600', '360', '6.000', '1.800'],
  ),
  QuizItem(
    'Which drink is made from fermented grapes?',
    'Fermente üzümden yapılan içecek hangisi?',
    ['Wine', 'Beer', 'Cider', 'Sake'],
    ['Şarap', 'Bira', 'Elma şarabı', 'Sake'],
  ),
  QuizItem(
    'Which is the smallest continent?',
    'En küçük kıta hangisi?',
    ['Australia', 'Europe', 'Antarctica', 'South America'],
    ['Avustralya', 'Avrupa', 'Antarktika', 'Güney Amerika'],
  ),
  QuizItem(
    'What do you call a baby cat?',
    'Yavru kediye ne denir?',
    ['Kitten', 'Puppy', 'Cub', 'Foal'],
    ['Yavru kedi', 'Köpek yavrusu', 'Aslan yavrusu', 'Tay'],
  ),
  QuizItem('Which famous ship sank in 1912?', '1912’de batan ünlü gemi hangisi?', [
    'Titanic',
    'Lusitania',
    'Britannic',
    'Queen Mary',
  ]),
  QuizItem(
    'What is the capital of India?',
    'Hindistan’ın başkenti neresi?',
    ['New Delhi', 'Mumbai', 'Kolkata', 'Bangalore'],
    ['Yeni Delhi', 'Mumbai', 'Kalküta', 'Bangalor'],
  ),
  QuizItem('How many players are on a basketball team on court?', 'Basketbolda bir takım sahada kaç oyuncuyla oynar?', [
    '5',
    '6',
    '7',
    '4',
  ]),
  QuizItem(
    'Which colour do you get by mixing blue and yellow?',
    'Mavi ile sarıyı karıştırınca hangi renk olur?',
    ['Green', 'Purple', 'Orange', 'Brown'],
    ['Yeşil', 'Mor', 'Turuncu', 'Kahverengi'],
  ),
  QuizItem(
    'Which is the largest island in the world?',
    'Dünyanın en büyük adası hangisi?',
    ['Greenland', 'Borneo', 'Madagascar', 'Great Britain'],
    ['Grönland', 'Borneo', 'Madagaskar', 'Büyük Britanya'],
  ),
  QuizItem(
    'What does a thermometer measure?',
    'Termometre neyi ölçer?',
    ['Temperature', 'Pressure', 'Humidity', 'Wind speed'],
    ['Sıcaklık', 'Basınç', 'Nem', 'Rüzgâr hızı'],
  ),
  QuizItem('Who wrote "Don Quixote"?', '"Don Kişot"u kim yazdı?', [
    'Miguel de Cervantes',
    'Gabriel García Márquez',
    'Victor Hugo',
    'Leo Tolstoy',
  ]),
  QuizItem(
    'Which is the hottest planet in the Solar System?',
    'Güneş Sistemi’nin en sıcak gezegeni hangisi?',
    ['Venus', 'Mercury', 'Mars', 'Jupiter'],
    ['Venüs', 'Merkür', 'Mars', 'Jüpiter'],
  ),
  QuizItem(
    'How many cards are in a standard deck (no jokers)?',
    'Standart bir iskambil destesinde (jokersiz) kaç kart var?',
    ['52', '54', '48', '56'],
  ),
  QuizItem(
    'Which country is famous for the maple leaf on its flag?',
    'Bayrağında akçaağaç yaprağı olan ülke hangisi?',
    ['Canada', 'Japan', 'Switzerland', 'Norway'],
    ['Kanada', 'Japonya', 'İsviçre', 'Norveç'],
  ),
  QuizItem(
    'What is the main ingredient of hummus?',
    'Humusun ana malzemesi nedir?',
    ['Chickpeas', 'Lentils', 'Beans', 'Peas'],
    ['Nohut', 'Mercimek', 'Fasulye', 'Bezelye'],
  ),
  QuizItem(
    'Which city is divided between Europe and Asia?',
    'Avrupa ve Asya arasında bölünmüş şehir hangisi?',
    ['Istanbul', 'Moscow', 'Athens', 'Cairo'],
    ['İstanbul', 'Moskova', 'Atina', 'Kahire'],
  ),
  QuizItem('How many hearts does an octopus have?', 'Ahtapotun kaç kalbi vardır?', ['3', '1', '2', '4']),
  QuizItem(
    'Which planet spins on its side?',
    'Yan yatmış hâlde dönen gezegen hangisi?',
    ['Uranus', 'Neptune', 'Saturn', 'Mars'],
    ['Uranüs', 'Neptün', 'Satürn', 'Mars'],
  ),
  QuizItem('What is 7 × 8?', '7 × 8 kaçtır?', ['56', '54', '64', '48']),
  QuizItem(
    'Which country has the Eiffel Tower?',
    'Eyfel Kulesi hangi ülkede?',
    ['France', 'Belgium', 'Italy', 'Germany'],
    ['Fransa', 'Belçika', 'İtalya', 'Almanya'],
  ),
];
