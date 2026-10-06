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
      route: "/plan"
    )
  }

  func placeholder(in context: Context) -> DaylyEntry { sample }

  func getSnapshot(in context: Context, completion: @escaping (DaylyEntry) -> Void) {
    completion(context.isPreview ? sample : load())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<DaylyEntry>) -> Void) {
    // Redraw after midnight so yesterday's plan does not linger.
    let tomorrow = Calendar.current.startOfDay(for: Date().addingTimeInterval(24 * 3600))
    completion(Timeline(entries: [load()], policy: .after(tomorrow.addingTimeInterval(60))))
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
        route: "/plan"
      )
    }
    let lines = (d?.string(forKey: "lines") ?? "").split(separator: "\n").map(String.init)
    return DaylyEntry(
      date: Date(),
      title: title,
      lines: lines,
      summary: d?.string(forKey: "summary") ?? "",
      route: d?.string(forKey: "route") ?? "/plan"
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
    default:
      VStack(alignment: .leading, spacing: 5) {
        Text(entry.title).font(.headline).foregroundColor(accent).lineLimit(1)
        ForEach(Array(entry.lines.prefix(family == .systemSmall ? 3 : 4).enumerated()), id: \.offset) { _, line in
          Text(line).font(.subheadline).foregroundColor(ink).lineLimit(1)
        }
        Spacer(minLength: 0)
        Text(entry.summary).font(.caption).foregroundColor(muted).lineLimit(2)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .widgetBackground(paper)
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
