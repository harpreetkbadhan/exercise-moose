import Foundation

let STATS_KEY = "dailyDoneCounts"  // ["2026-10-19": 4]
let STATS_KEEP_DAYS = 3 * 365  // the longest streak that can be counted; still a small dictionary
let CHART_DAYS = 7

struct DayCount: Identifiable, Equatable {
    let day: Date
    let count: Int
    var id: Date { day }
}

/// "2026-10-19" in your local timezone; zero-padded so keys sort by date.
func dayKey(_ date: Date, calendar: Calendar = .current) -> String {
    let parts = calendar.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
}

/// Adds one break to `date` and drops days older than STATS_KEEP_DAYS. Returns a new dictionary.
func recordingBreak(in counts: [String: Int], on date: Date, calendar: Calendar = .current) -> [String: Int] {
    let key = dayKey(date, calendar: calendar)
    let oldest = calendar.date(byAdding: .day, value: -STATS_KEEP_DAYS, to: date) ?? date
    let cutoff = dayKey(oldest, calendar: calendar)
    return counts
        .filter { $0.key > cutoff }
        .merging([key: (counts[key] ?? 0) + 1]) { _, new in new }
}

/// Days in a row with at least one break. If today has none yet, counts back from yesterday,
/// so the streak doesn't vanish at midnight.
func streak(counts: [String: Int], today: Date, calendar: Calendar = .current) -> Int {
    let hasBreak = { (day: Date) in (counts[dayKey(day, calendar: calendar)] ?? 0) > 0 }
    let start = hasBreak(today) ? today : (calendar.date(byAdding: .day, value: -1, to: today) ?? today)
    return sequence(first: start) { calendar.date(byAdding: .day, value: -1, to: $0) }
        .prefix(STATS_KEEP_DAYS)
        .prefix(while: hasBreak)
        .count
}

/// The last CHART_DAYS days, oldest first, for the Settings chart.
func lastDays(counts: [String: Int], today: Date, calendar: Calendar = .current) -> [DayCount] {
    (0..<CHART_DAYS).reversed()
        .compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
        .map { DayCount(day: $0, count: counts[dayKey($0, calendar: calendar)] ?? 0) }
}

/// Saved break history.
enum Stats {
    static var counts: [String: Int] {
        UserDefaults.standard.dictionary(forKey: STATS_KEY) as? [String: Int] ?? [:]
    }

    static var today: Int { counts[dayKey(Date())] ?? 0 }
    static var currentStreak: Int { streak(counts: counts, today: Date()) }
    static var week: [DayCount] { lastDays(counts: counts, today: Date()) }

    static func recordBreak() {
        UserDefaults.standard.set(recordingBreak(in: counts, on: Date()), forKey: STATS_KEY)
    }
}
