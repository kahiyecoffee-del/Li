import SwiftUI
import WidgetKit

/// Today's program on the Home Screen and Lock Screen. The app writes the
/// data into the shared App Group (home_widget) whenever tasks change.
private let appGroup = "group.com.dayly.app"
private let accent = Color(red: 0x4A / 255, green: 0x6B / 255, blue: 0x52 / 255)
private let paper = Color(red: 1, green: 0xFD / 255, blue: 0xFA / 255)
private let ink = Color(red: 0x2A / 255, green: 0x23 / 255, blue: 0x1E / 255)
private let muted = Color(red: 0x7B / 255, green: 0x6F / 255, blue: 0x64 / 255)

private var turkish: Bool { Locale.preferredLanguages.first?.hasPrefix("tr") ?? false }

struct DaylyEntry: TimelineEntry {
  let date: Date
  let title: String
  let lines: [String]
  let summary: String
  let route: String
  /// The next task and the label of its "Done" button (medium widget).
  var nextId: String = ""
  var doneLabel: String = ""
  /// Lio's pose ("happy", "curious", …); alternates now and then so Lio moves.
  var pose: String = "happy"
  /// A small tilt that changes with the pose, for a lively feel.
  var tilt: Double = 0
}

/// Lio's second pose for each mood: the widget swaps between the two every
/// 20 minutes with an animated transition (iOS 17+). Asleep at night.
private func partnerPose(_ mood: String) -> String {
  switch mood {
  case "happy": return "heart"
  case "curious": return "thoughtful"
  case "excited": return "happy"
  case "thoughtful": return "curious"
  default: return mood
  }
}

private func dayKey(_ d: Date) -> String {
  let f = DateFormatter()
  f.calendar = Calendar(identifier: .gregorian)
  f.locale = Locale(identifier: "en_US_POSIX")
  f.dateFormat = "yyyy-MM-dd"
  return f.string(from: d)
}

struct DaylyProvider: TimelineProvider {
  var sample: DaylyEntry {
    DaylyEntry(
      date: Date(),
      title: turkish ? "Bugün" : "Today",
      lines: turkish ? ["09:00  Ekip toplantısı", "•  Spor", "•  Annemi ara"] : ["09:00  Team meeting", "•  Workout", "•  Call mom"],
      summary: turkish ? "Bugün 3 iş kaldı" : "3 things left today",
      route: "/plan",
      pose: "happy"
    )
  }

  func placeholder(in context: Context) -> DaylyEntry { sample }

  func getSnapshot(in context: Context, completion: @escaping (DaylyEntry) -> Void) {
    completion(context.isPreview ? sample : load())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<DaylyEntry>) -> Void) {
    let base = load()
    let now = Date()
    // Redraw after midnight so yesterday's plan does not linger.
    let midnight = Calendar.current.startOfDay(for: now.addingTimeInterval(24 * 3600)).addingTimeInterval(60)
    let mood = base.pose
    var entries: [DaylyEntry] = []
    let tilts: [Double] = [0, -6, 4, -3, 6, 0, -5, 3, 0]
    // Every 20 minutes for 3 hours Lio switches pose and tilts a little.
    for i in 0..<9 {
      let at = now.addingTimeInterval(Double(i) * 20 * 60)
      if at >= midnight { break }
      let e = DaylyEntry(
        date: at,
        title: base.title,
        lines: base.lines,
        summary: base.summary,
        route: base.route,
        nextId: base.nextId,
        doneLabel: base.doneLabel,
        pose: i % 2 == 0 ? mood : partnerPose(mood),
        tilt: mood == "sleepy" ? 0 : tilts[i]
      )
      entries.append(e)
    }
    let next = min(now.addingTimeInterval(3 * 3600), midnight)
    completion(Timeline(entries: entries, policy: .after(next)))
  }

  func load() -> DaylyEntry {
    let d = UserDefaults(suiteName: appGroup)
    let title = d?.string(forKey: "title") ?? "Dayly"
    guard d?.string(forKey: "day") == dayKey(Date()) else {
      return DaylyEntry(
        date: Date(),
        title: turkish ? "Bugün" : "Today",
        lines: [],
        summary: d?.string(forKey: "staleHint") ?? (turkish ? "Bugünün planı için Dayly'yi aç" : "Open Dayly to see today's plan"),
        route: "/plan",
        pose: "curious"
      )
    }
    let lines = (d?.string(forKey: "lines") ?? "").split(separator: "\n").map(String.init)
    return DaylyEntry(
      date: Date(),
      title: title,
      lines: lines,
      summary: d?.string(forKey: "summary") ?? "",
      route: d?.string(forKey: "route") ?? "/plan",
      nextId: d?.string(forKey: "nextId") ?? "",
      doneLabel: d?.string(forKey: "doneLabel") ?? "",
      pose: d?.string(forKey: "mood") ?? "happy"
    )
  }
}

struct DaylyWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: DaylyEntry

  private var url: URL? {
    var c = URLComponents()
    c.scheme = "dayly"
    c.host = "open"
    c.queryItems = [URLQueryItem(name: "homeWidget", value: nil), URLQueryItem(name: "r", value: entry.route)]
    return c.url
  }

  /// Opens the app, which ticks the next task off.
  private var doneURL: URL? {
    var c = URLComponents()
    c.scheme = "dayly"
    c.host = "open"
    c.queryItems = [URLQueryItem(name: "homeWidget", value: nil), URLQueryItem(name: "r", value: "/plan?done=\(entry.nextId)")]
    return c.url
  }

  var body: some View {
    content.widgetURL(url)
  }

  @ViewBuilder private var content: some View {
    switch family {
    case .accessoryRectangular:
      VStack(alignment: .leading, spacing: 1) {
        Text(entry.title).font(.headline).lineLimit(1)
        if entry.lines.isEmpty {
          Text(entry.summary).font(.caption).lineLimit(2)
        } else {
          ForEach(Array(entry.lines.prefix(2).enumerated()), id: \.offset) { _, line in
            Text(line).font(.caption).lineLimit(1)
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .accessoryBackground()
    case .systemMedium:
      HStack(alignment: .bottom, spacing: 8) {
        textColumn(maxLines: 4)
        lio(size: 74)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .widgetBackground(paper)
    default:
      VStack(alignment: .leading, spacing: 4) {
        HStack(alignment: .top) {
          Text(entry.title).font(.headline).foregroundColor(accent).lineLimit(1)
          Spacer(minLength: 2)
          lio(size: 36)
        }
        ForEach(Array(entry.lines.prefix(2).enumerated()), id: \.offset) { _, line in
          Text(line).font(.footnote).foregroundColor(ink).lineLimit(1)
        }
        Spacer(minLength: 0)
        Text(entry.summary).font(.caption2).foregroundColor(muted).lineLimit(2)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .widgetBackground(paper)
    }
  }

  private func textColumn(maxLines: Int) -> some View {
    VStack(alignment: .leading, spacing: 5) {
      Text(entry.title).font(.headline).foregroundColor(accent).lineLimit(1)
      ForEach(Array(entry.lines.prefix(maxLines).enumerated()), id: \.offset) { _, line in
        Text(line).font(.subheadline).foregroundColor(ink).lineLimit(1)
      }
      Spacer(minLength: 0)
      if !entry.nextId.isEmpty, !entry.doneLabel.isEmpty, let done = doneURL {
        Link(destination: done) {
          Text(entry.doneLabel)
            .font(.caption.weight(.semibold))
            .foregroundColor(.white)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(accent))
        }
      } else {
        Text(entry.summary).font(.caption).foregroundColor(muted).lineLimit(2)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  /// Lio, swapping pose between timeline entries with a little hop.
  @ViewBuilder private func lio(size: CGFloat) -> some View {
    let image = Image("lio_\(entry.pose)")
      .resizable()
      .scaledToFit()
      .frame(height: size)
      .rotationEffect(.degrees(entry.tilt))
      .id(entry.pose)
      .accessibilityHidden(true)
    if #available(iOSApplicationExtension 17.0, *) {
      image.transition(.push(from: .bottom))
    } else {
      image
    }
  }
}

extension View {
  @ViewBuilder func widgetBackground(_ color: Color) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(for: .widget) { color }
    } else {
      padding().background(color)
    }
  }

  @ViewBuilder func accessoryBackground() -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(for: .widget) { Color.clear }
    } else {
      self
    }
  }
}

struct DaylyWidget: Widget {
  let kind = "DaylyWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: DaylyProvider()) { entry in
      DaylyWidgetView(entry: entry)
    }
    .configurationDisplayName(turkish ? "Bugünün planı" : "Today's plan")
    .description(turkish ? "Günlük programın bir bakışta. Düzenlemek için dokun." : "Your day at a glance. Tap to edit it.")
    .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
  }
}

@main
struct DaylyWidgetBundle: WidgetBundle {
  var body: some Widget {
    DaylyWidget()
  }
}
