/// Ready-made messages for everyday situations, in Turkish and English, in
/// three tones. Placeholders: {name}, {what}, {when}, {company}. Lio fills
/// them from the user's answers; nothing is generated, so the wording is
/// always natural and safe.
library;

enum Tone { warm, formal, short }

/// What Lio asks before writing. [name] is optional everywhere.
enum TemplateField { name, what, when, company }

class MessageTemplate {
  const MessageTemplate({required this.id, required this.emoji, required this.fields, required this.texts});

  final String id;
  final String emoji;
  final List<TemplateField> fields;

  /// language → tone → variants.
  final Map<String, Map<Tone, List<String>>> texts;

  List<String> variants(String lang, Tone tone) => (texts[lang] ?? texts['en']!)[tone]!;
}

abstract final class MessageTemplates {
  static MessageTemplate byId(String id) => all.firstWhere((t) => t.id == id);

  /// Fills placeholders. An empty optional name is dropped cleanly
  /// ("Merhaba {name}," → "Merhaba,").
  static String fill(String text, Map<TemplateField, String> values) {
    var out = text;
    for (final f in TemplateField.values) {
      final v = (values[f] ?? '').trim();
      final ph = '{${f.name}}';
      if (v.isEmpty) {
        out = out.replaceAll(ph, '');
      } else {
        out = out.replaceAll(ph, v);
      }
    }
    return out
        .replaceAll(RegExp(r'^\s*[,;:]\s*'), '')
        .replaceAllMapped(RegExp(r'[ \t]+([,.!?])'), (m) => m[1]!)
        .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
        .trim();
  }

  static const all = <MessageTemplate>[
    MessageTemplate(
      id: 'birthday',
      emoji: '🎂',
      fields: [TemplateField.name],
      texts: {
        'tr': {
          Tone.warm: [
            'İyi ki doğdun {name}! 🎉 Yeni yaşın sağlık, huzur ve bol kahkahayla geçsin. Nice güzel yıllara!',
            'Doğum günün kutlu olsun {name}! Hayatında hep seni mutlu eden insanlar ve güzel sürprizler olsun. 🎂',
          ],
          Tone.formal: [
            'Sayın {name}, doğum gününüzü içtenlikle kutlar; sağlık, mutluluk ve başarı dolu bir yıl dilerim.',
            'Doğum gününüz kutlu olsun {name}. Yeni yaşınızın size ve sevdiklerinize güzellikler getirmesini dilerim.',
          ],
          Tone.short: ['İyi ki doğdun {name}! 🎉', 'Nice mutlu yıllara {name}! 🎂'],
        },
        'en': {
          Tone.warm: [
            'Happy birthday {name}! 🎉 Wishing you a year full of health, calm and lots of laughter.',
            'Happy birthday {name}! May this year bring you great people and lovely surprises. 🎂',
          ],
          Tone.formal: [
            'Dear {name}, warmest wishes on your birthday. I wish you a healthy, happy and successful year ahead.',
            'Happy birthday {name}. Wishing you and your loved ones every happiness in the year ahead.',
          ],
          Tone.short: ['Happy birthday {name}! 🎉', 'Have a wonderful birthday {name}! 🎂'],
        },
      },
    ),
    MessageTemplate(
      id: 'thanks',
      emoji: '🙏',
      fields: [TemplateField.name, TemplateField.what],
      texts: {
        'tr': {
          Tone.warm: [
            '{name}, {what} için çok teşekkür ederim! Gerçekten çok işime yaradı, sana bir kahve borcum var. ☕',
            'Çok sağ ol {name}! {what} için ayırdığın zaman ve emek benim için çok değerli.',
          ],
          Tone.formal: [
            'Sayın {name}, {what} konusundaki desteğiniz için teşekkür ederim. Yardımınız çok değerliydi.',
            '{name}, {what} için gösterdiğiniz ilgi ve emek için içtenlikle teşekkür ederim.',
          ],
          Tone.short: ['{what} için çok teşekkürler {name}! 🙏', 'Eline sağlık {name}, {what} harika oldu!'],
        },
        'en': {
          Tone.warm: [
            'Thank you so much for {what}, {name}! It really helped — I owe you a coffee. ☕',
            'Thanks a lot {name}! The time and effort you put into {what} means a lot to me.',
          ],
          Tone.formal: [
            'Dear {name}, thank you for your support with {what}. Your help was greatly appreciated.',
            '{name}, thank you sincerely for your attention and effort regarding {what}.',
          ],
          Tone.short: ['Thanks so much for {what}, {name}! 🙏', 'Great job on {what}, {name} — thank you!'],
        },
      },
    ),
    MessageTemplate(
      id: 'apology',
      emoji: '🤝',
      fields: [TemplateField.name, TemplateField.what],
      texts: {
        'tr': {
          Tone.warm: [
            '{name}, {what} için gerçekten özür dilerim. Seni üzmek istemezdim; telafi etmek için ne yapabilirim?',
            'Biliyorum, {what} hiç hoş olmadı. Özür dilerim {name}. Bir daha olmaması için dikkat edeceğim.',
          ],
          Tone.formal: [
            'Sayın {name}, {what} nedeniyle yaşanan aksaklık için özür dilerim. Konuyu en kısa sürede telafi edeceğim.',
            '{name}, {what} konusunda yaşanan durum için kusura bakmayın. Gerekli önlemleri alıyorum.',
          ],
          Tone.short: ['{what} için özür dilerim {name}.', 'Kusura bakma {name}, {what} benim hatamdı.'],
        },
        'en': {
          Tone.warm: [
            "{name}, I'm really sorry about {what}. I never meant to upset you — how can I make it right?",
            "I know {what} wasn't okay. I'm sorry, {name}. I'll make sure it doesn't happen again.",
          ],
          Tone.formal: [
            'Dear {name}, please accept my apologies for {what}. I will put it right as soon as possible.',
            "{name}, I'm sorry for the inconvenience caused by {what}. I am taking steps to prevent it.",
          ],
          Tone.short: ['Sorry about {what}, {name}.', 'My apologies for {what}, {name}.'],
        },
      },
    ),
    MessageTemplate(
      id: 'late',
      emoji: '⏰',
      fields: [TemplateField.name, TemplateField.when],
      texts: {
        'tr': {
          Tone.warm: [
            '{name}, kusura bakma, biraz gecikeceğim — {when} orada olurum. Sen başlayabilirsin! 🙏',
            'Yoldayım ama trafik var {name} 😅 {when} gibi oradayım, beklettiğim için kusura bakma.',
          ],
          Tone.formal: [
            'Sayın {name}, beklenmedik bir gecikme nedeniyle {when} katılabileceğim. Anlayışınız için teşekkür ederim.',
            '{name}, toplantıya {when} katılabileceğimi bildirmek isterim. Gecikme için özür dilerim.',
          ],
          Tone.short: ['Biraz gecikeceğim, {when} oradayım.', '{name}, {when} gelebilirim, kusura bakma.'],
        },
        'en': {
          Tone.warm: [
            "Sorry {name}, I'm running a bit late — I'll be there {when}. Feel free to start! 🙏",
            "On my way but stuck in traffic 😅 I'll be there {when}, {name}. Sorry to keep you waiting.",
          ],
          Tone.formal: [
            'Dear {name}, due to an unexpected delay I will join {when}. Thank you for your understanding.',
            '{name}, I wanted to let you know I will be able to join {when}. Apologies for the delay.',
          ],
          Tone.short: ['Running late, there {when}.', "{name}, I'll be there {when} — sorry!"],
        },
      },
    ),
    MessageTemplate(
      id: 'leave',
      emoji: '🗓️',
      fields: [TemplateField.name, TemplateField.when, TemplateField.what],
      texts: {
        'tr': {
          Tone.warm: [
            'Merhaba {name}, {what} nedeniyle {when} izin alabilir miyim? İşlerimi önceden toparlayıp devredeceğim.',
            '{name}, {when} {what} sebebiyle izinli olmam gerekiyor. Uygun olursa çok sevinirim, acil bir şey olursa telefonla ulaşabilirsin.',
          ],
          Tone.formal: [
            'Sayın {name}, {what} nedeniyle {when} izin talep ediyorum. Sorumluluklarımı önceden planlayıp ilgili kişilere devredeceğim. Onayınızı rica ederim.',
            '{name}, {when} tarihinde {what} sebebiyle izinli olmam gerekmektedir. Bilgilerinize sunar, onayınızı rica ederim.',
          ],
          Tone.short: [
            '{name}, {what} için {when} izin alabilir miyim?',
            '{when} izinli olmam gerekiyor ({what}). Uygun mu?',
          ],
        },
        'en': {
          Tone.warm: [
            "Hi {name}, could I take {when} off for {what}? I'll wrap up and hand over my work beforehand.",
            '{name}, I need to be off {when} for {what}. If anything urgent comes up, you can reach me by phone.',
          ],
          Tone.formal: [
            'Dear {name}, I would like to request leave {when} due to {what}. I will plan and hand over my responsibilities in advance. I would appreciate your approval.',
            '{name}, I need to be away {when} because of {what}. I kindly request your approval.',
          ],
          Tone.short: ['{name}, may I take {when} off for {what}?', 'I need {when} off ({what}). Is that okay?'],
        },
      },
    ),
    MessageTemplate(
      id: 'decline',
      emoji: '🙅',
      fields: [TemplateField.name, TemplateField.what],
      texts: {
        'tr': {
          Tone.warm: [
            'Aklıma getirdiğin için çok teşekkürler {name}! Ama bu sefer {what} için müsait değilim. Bir dahaki sefere mutlaka! 😊',
            '{name}, çok isterdim ama {what} şu an bana uymuyor. Anlayışın için teşekkür ederim 🙏',
          ],
          Tone.formal: [
            'Sayın {name}, {what} teklifiniz için teşekkür ederim. Ancak mevcut yoğunluğum nedeniyle bu kez katılamayacağım.',
            '{name}, {what} konusundaki davetiniz için teşekkürler. Şu an için olumlu yanıt veremiyorum; ileride tekrar değerlendirmeyi isterim.',
          ],
          Tone.short: [
            'Teşekkürler {name} ama {what} için müsait değilim.',
            'Bu sefer olmayacak {name}, kusura bakma.',
          ],
        },
        'en': {
          Tone.warm: [
            "Thanks so much for thinking of me, {name}! I can't make {what} this time, but next time for sure! 😊",
            "{name}, I'd love to, but {what} doesn't work for me right now. Thanks for understanding 🙏",
          ],
          Tone.formal: [
            'Dear {name}, thank you for the offer regarding {what}. Unfortunately, I am unable to take part this time.',
            '{name}, thank you for the invitation to {what}. I can’t commit at the moment but would be glad to revisit it later.',
          ],
          Tone.short: ["Thanks {name}, but I can't do {what}.", 'Not this time, {name} — sorry!'],
        },
      },
    ),
    MessageTemplate(
      id: 'congrats',
      emoji: '🎉',
      fields: [TemplateField.name, TemplateField.what],
      texts: {
        'tr': {
          Tone.warm: [
            'Tebrikler {name}! {what} haberini duyunca çok sevindim, bunu fazlasıyla hak ettin! 🎉',
            'Vay be {name}! {what} için kocaman tebrikler, seninle gurur duyuyorum! 👏',
          ],
          Tone.formal: [
            'Sayın {name}, {what} vesilesiyle sizi tebrik eder, başarılarınızın devamını dilerim.',
            '{name}, {what} için tebriklerimi sunarım. Yeni döneminizde başarılar dilerim.',
          ],
          Tone.short: ['Tebrikler {name}! 🎉', '{what} için tebrikler {name}! 👏'],
        },
        'en': {
          Tone.warm: [
            'Congratulations {name}! So happy to hear about {what} — you truly deserve it! 🎉',
            'Wow {name}! Huge congrats on {what}, I’m so proud of you! 👏',
          ],
          Tone.formal: [
            'Dear {name}, congratulations on {what}. I wish you continued success.',
            '{name}, please accept my congratulations on {what}. Best wishes for this new chapter.',
          ],
          Tone.short: ['Congratulations {name}! 🎉', 'Congrats on {what}, {name}! 👏'],
        },
      },
    ),
    MessageTemplate(
      id: 'condolence',
      emoji: '🕊️',
      fields: [TemplateField.name],
      texts: {
        'tr': {
          Tone.warm: [
            'Başın sağ olsun {name}. Çok üzüldüm. Bir şeye ihtiyacın olursa ya da sadece konuşmak istersen buradayım.',
            'Çok üzgünüm {name}. Sana ve ailene sabır diliyorum. Yanındayım, ne zaman istersen ara.',
          ],
          Tone.formal: [
            'Sayın {name}, kaybınızdan dolayı derin üzüntü duydum. Başınız sağ olsun; size ve ailenize sabır dilerim.',
            'Acınızı paylaşıyorum {name}. Allah rahmet eylesin, başınız sağ olsun.',
          ],
          Tone.short: ['Başın sağ olsun {name}. Yanındayım.', 'Çok üzüldüm {name}, başın sağ olsun.'],
        },
        'en': {
          Tone.warm: [
            "I'm so sorry for your loss, {name}. If you need anything, or just want to talk, I'm here.",
            "I'm so sorry, {name}. Thinking of you and your family. Call me anytime.",
          ],
          Tone.formal: [
            'Dear {name}, please accept my deepest condolences. My thoughts are with you and your family.',
            '{name}, I was very sorry to hear of your loss. Wishing you strength at this difficult time.',
          ],
          Tone.short: ["So sorry for your loss, {name}. I'm here.", 'My condolences, {name}.'],
        },
      },
    ),
    MessageTemplate(
      id: 'payment',
      emoji: '💸',
      fields: [TemplateField.name, TemplateField.what],
      texts: {
        'tr': {
          Tone.warm: [
            'Selam {name}! Unutmuşsundur diye hatırlatayım: {what} ödemesi hâlâ duruyor. Uygun olduğunda gönderirsen sevinirim 😊',
            '{name}, rahatsız etmek istemem ama {what} konusunu bir hatırlatayım dedim. Müsait olunca bakabilir misin?',
          ],
          Tone.formal: [
            'Sayın {name}, {what} tutarındaki ödemenin henüz tarafımıza ulaşmadığını hatırlatmak isterim. En kısa sürede ödemenizi rica ederim.',
            '{name}, {what} ile ilgili ödemenin vadesi geçmiştir. Bilgilerinize sunar, ödemenizi rica ederim.',
          ],
          Tone.short: [
            '{name}, {what} ödemesini hatırlatırım 🙏',
            '{what} hâlâ açıkta {name}, müsait olunca gönderir misin?',
          ],
        },
        'en': {
          Tone.warm: [
            'Hi {name}! Just a friendly reminder about {what} — whenever you get a chance 😊',
            "{name}, sorry to bother you, just a quick reminder about {what}. Could you check when you're free?",
          ],
          Tone.formal: [
            'Dear {name}, this is a reminder that the payment for {what} has not yet been received. Please arrange payment at your earliest convenience.',
            '{name}, the payment for {what} is now overdue. Kindly arrange payment.',
          ],
          Tone.short: ['Reminder about {what}, {name} 🙏', '{name}, {what} is still pending — could you send it?'],
        },
      },
    ),
    MessageTemplate(
      id: 'complaint',
      emoji: '📣',
      fields: [TemplateField.company, TemplateField.what],
      texts: {
        'tr': {
          Tone.warm: [
            'Merhaba {company} ekibi, {what} ile ilgili bir sorun yaşıyorum. Yardımcı olursanız çok sevinirim, teşekkürler!',
            'Merhaba, {company} müşterisiyim. {what} konusunda bir sıkıntı var; nasıl çözebiliriz?',
          ],
          Tone.formal: [
            'Sayın {company} Müşteri Hizmetleri,\n\n{what} konusunda yaşadığım sorunu bildirmek isterim. Sorunun en kısa sürede çözülmesini ve tarafıma bilgi verilmesini rica ederim.\n\nSaygılarımla',
            'Sayın {company} Yetkilisi,\n\n{what} ile ilgili şikâyetimi iletmek istiyorum. Gerekli incelemenin yapılarak tarafıma dönüş sağlanmasını talep ederim.\n\nSaygılarımla',
          ],
          Tone.short: [
            '{company}: {what} sorunu yaşıyorum, yardımcı olur musunuz?',
            'Merhaba {company}, {what} hakkında destek rica ediyorum.',
          ],
        },
        'en': {
          Tone.warm: [
            "Hi {company} team, I'm having an issue with {what}. I'd really appreciate your help — thanks!",
            "Hello, I'm a {company} customer. There's a problem with {what}; how can we sort it out?",
          ],
          Tone.formal: [
            'Dear {company} Customer Service,\n\nI would like to report a problem regarding {what}. I kindly request that it be resolved as soon as possible and that you keep me informed.\n\nKind regards',
            'Dear {company},\n\nI am writing to file a complaint about {what}. Please investigate and get back to me.\n\nKind regards',
          ],
          Tone.short: [
            '{company}: having an issue with {what}, can you help?',
            'Hi {company}, I need support with {what}.',
          ],
        },
      },
    ),
    MessageTemplate(
      id: 'job',
      emoji: '💼',
      fields: [TemplateField.name, TemplateField.company, TemplateField.what],
      texts: {
        'tr': {
          Tone.warm: [
            'Merhaba {name}, {company} bünyesindeki {what} pozisyonu ilgimi çekti. Deneyimlerimin ekibinize katkı sağlayacağına inanıyorum. Özgeçmişimi ekte paylaşıyorum; görüşme fırsatı için çok sevinirim.',
            'Merhaba {name}, {company} ekibinde {what} olarak çalışmayı çok isterim. Kısa bir görüşme için uygun bir zamanınız olur mu? Özgeçmişim ekte.',
          ],
          Tone.formal: [
            'Sayın {name},\n\n{company} bünyesinde açık olan {what} pozisyonuna başvurmak istiyorum. Özgeçmişimi bilgilerinize sunar, uygun görmeniz hâlinde görüşme fırsatı için teşekkür ederim.\n\nSaygılarımla',
            'Sayın {name},\n\n{what} pozisyonu için başvurumu ekte yer alan özgeçmişimle birlikte iletiyorum. {company} ailesine katkı sunmaktan memnuniyet duyarım.\n\nSaygılarımla',
          ],
          Tone.short: [
            '{what} pozisyonu için başvuruyorum, özgeçmişim ekte.',
            '{company} – {what} başvurusu: özgeçmişim ektedir.',
          ],
        },
        'en': {
          Tone.warm: [
            "Hi {name}, the {what} role at {company} caught my eye. I believe my experience could add real value to your team. My CV is attached — I'd love the chance to talk.",
            "Hi {name}, I'd love to join {company} as {what}. Would you have time for a short call? My CV is attached.",
          ],
          Tone.formal: [
            'Dear {name},\n\nI would like to apply for the {what} position at {company}. Please find my CV attached. Thank you for considering my application.\n\nKind regards',
            'Dear {name},\n\nPlease accept my application for the {what} position, with my CV attached. I would be glad to contribute to {company}.\n\nKind regards',
          ],
          Tone.short: ['Applying for the {what} role — CV attached.', '{company} – {what} application: CV attached.'],
        },
      },
    ),
    MessageTemplate(
      id: 'landlord',
      emoji: '🏠',
      fields: [TemplateField.name, TemplateField.what],
      texts: {
        'tr': {
          Tone.warm: [
            'Merhaba {name}, evde {what} sorunu var. Müsait olduğunuzda bakılabilir mi? Şimdiden teşekkür ederim.',
            'Merhaba {name}, {what} konusunda yardımınıza ihtiyacım var. Uygun bir zaman söylerseniz evde olurum.',
          ],
          Tone.formal: [
            'Sayın {name}, kiracısı olduğum dairede {what} sorunu bulunmaktadır. Gerekli onarımın en kısa sürede yapılmasını rica ederim.',
            '{name}, dairede yaşanan {what} sorununu bilgilerinize sunarım. Çözüm için dönüşünüzü rica ederim.',
          ],
          Tone.short: ['{name}, evde {what} sorunu var, bakılabilir mi?', '{what} için ustaya ihtiyaç var {name}.'],
        },
        'en': {
          Tone.warm: [
            "Hi {name}, there's a problem with {what} in the flat. Could someone take a look when convenient? Thanks in advance.",
            "Hello {name}, I need your help with {what}. Let me know a good time and I'll be home.",
          ],
          Tone.formal: [
            'Dear {name}, I would like to report an issue with {what} in the property I rent. I kindly request that it be repaired as soon as possible.',
            '{name}, please be informed of the {what} problem in the flat. I would appreciate a response regarding a fix.',
          ],
          Tone.short: [
            '{name}, {what} needs fixing — can someone check?',
            'Problem with {what}, {name}. Can you send someone?',
          ],
        },
      },
    ),
  ];
}
