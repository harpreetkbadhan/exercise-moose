import AppKit

// The menu's header, set in the break card's grid: when the next break comes, your streak, and Claude Code's
// usage as bars. The actions below it stay native menu items.

let MENU_HEADER_WIDTH: CGFloat = 300
let MENU_HEADER_INSET: CGFloat = 15  // lines up with the native items' text and separators below
let MENU_COLUMN_GAP: CGFloat = 16
let MENU_FIGURE_SIZE: CGFloat = 30
let USAGE_LABEL_WIDTH: CGFloat = 58
let USAGE_PERCENT_WIDTH: CGFloat = 46

/// A label, a figure set large, and its unit: "Next break / 30 / min".
struct BreakStatus: Equatable {
    let label: String
    let figure: String
    let unit: String
}

func breakStatus(nextBreak: Date?, pausedUntil: Date?, offUntil: Date?, isWaitingForCall: Bool, isShowing: Bool,
                 now: Date, calendar: Calendar = .current) -> BreakStatus {
    if let pausedUntil, pausedUntil > now {
        return BreakStatus(label: "Paused until", figure: formatReset(pausedUntil, now: now, calendar: calendar), unit: "")
    }
    if let offUntil, offUntil > now {
        return BreakStatus(label: "Off until", figure: formatReset(offUntil, now: now, calendar: calendar), unit: "")
    }
    if isWaitingForCall { return BreakStatus(label: "Next break", figure: "Waiting", unit: "for your call") }
    guard !isShowing, let nextBreak, nextBreak > now else { return BreakStatus(label: "Next break", figure: "Now", unit: "") }
    let minutes = max(1, Int((nextBreak.timeIntervalSince(now) / 60).rounded(.up)))
    return BreakStatus(label: "Next break", figure: "\(minutes)", unit: "min")
}

func streakStatus(counts: [String: Int], goal: Int, now: Date, calendar: Calendar = .current) -> BreakStatus {
    let today = counts[dayKey(now, calendar: calendar)] ?? 0
    let days = streak(counts: counts, today: now, calendar: calendar)
    guard days > 0 else { return BreakStatus(label: "Today", figure: "\(today) of \(goal)", unit: "breaks") }
    return BreakStatus(label: "Streak", figure: days == 1 ? "1 day" : "\(days) days", unit: "\(today) of \(goal) today")
}

/// One Claude Code limit as a bar: how full, what to know about it, and whether it's running high.
struct UsageRow: Equatable {
    let label: String
    let percent: Double
    let detail: String
    let isHigh: Bool
}

func usageRows(_ usage: ClaudeUsage, now: Date, calendar: Calendar = .current) -> [UsageRow] {
    let context = usage.contextPercent.map { percent in
        let parts = [usage.contextSize.map { "of \(formatContextSize($0))" },
                     percent >= CONTEXT_COMPACT_PERCENT ? "time to /compact" : nil].compactMap { $0 }
        return UsageRow(label: "Context", percent: percent, detail: parts.joined(separator: ", "),
                        isHigh: percent >= USAGE_WARNING_PERCENT)
    }
    let limit = { (label: String, percent: Double?, reset: Date?) -> UsageRow? in
        percent.map {
            UsageRow(label: label, percent: $0,
                     detail: reset.map { "resets \(formatReset($0, now: now, calendar: calendar))" } ?? "",
                     isHigh: $0 >= USAGE_WARNING_PERCENT)
        }
    }
    return [context, limit("5-hour", usage.fiveHourPercent, usage.fiveHourResetsAt),
            limit("Weekly", usage.weeklyPercent, usage.weeklyResetsAt)].compactMap { $0 }
}

/// The header item's view, rebuilt each time the menu opens. Text uses the menu's own label colours, so it stays
/// legible on the menu's material in Light and Dark Mode.
final class MenuHeaderView: NSView {
    private let stack = NSStackView()
    private var contentWidth: CGFloat { MENU_HEADER_WIDTH - 2 * MENU_HEADER_INSET }

    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: MENU_HEADER_WIDTH, height: 1))
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 0
        stack.edgeInsets = NSEdgeInsets(top: 8, left: MENU_HEADER_INSET, bottom: 10, right: MENU_HEADER_INSET)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.widthAnchor.constraint(equalToConstant: MENU_HEADER_WIDTH),
        ])
    }

    required init?(coder: NSCoder) { nil }

    /// `claudeTitle` nil hides the Claude Code section (its status line isn't connected).
    func update(next: BreakStatus, streak: BreakStatus, claudeTitle: String?, rows: [UsageRow]) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let columnWidth = ((contentWidth - MENU_COLUMN_GAP) / 2).rounded(.down)
        let status = NSStackView(views: [statusBlock(next, width: columnWidth), statusBlock(streak, width: columnWidth)])
        status.alignment = .top
        status.spacing = MENU_COLUMN_GAP
        stack.addArrangedSubview(status)
        if let claudeTitle {
            let rule = FillView(.labelColor)
            rule.heightAnchor.constraint(equalToConstant: 2).isActive = true
            rule.widthAnchor.constraint(equalToConstant: contentWidth).isActive = true
            stack.addArrangedSubview(rule)
            stack.setCustomSpacing(12, after: status)
            let title = gridLabel(claudeTitle, size: 12, weight: .bold, color: .labelColor)
            stack.addArrangedSubview(title)
            stack.setCustomSpacing(10, after: rule)
            stack.setCustomSpacing(8, after: title)
            for row in rows {
                let view = usageRow(row)
                stack.addArrangedSubview(view)
                stack.setCustomSpacing(8, after: view)
            }
        }
        layoutSubtreeIfNeeded()
        setFrameSize(NSSize(width: MENU_HEADER_WIDTH, height: stack.fittingSize.height))
    }

    /// Label above, the figure large with its unit on the same baseline when it fits ("31 min"), else below it
    /// ("1 day" over "6 of 6 today").
    private func statusBlock(_ status: BreakStatus, width: CGFloat) -> NSView {
        let label = gridLabel(status.label, size: 11, weight: .bold, color: .secondaryLabelColor)
        let size = fittingFontSize(status.figure, maxSize: MENU_FIGURE_SIZE, width: width, tracking: -0.03)
        let figure = gridLabel(status.figure, size: size, weight: .bold, color: .labelColor, tracking: -0.03)
        let line = NSStackView(views: [figure])
        line.alignment = .firstBaseline
        line.spacing = 4
        var views: [NSView] = [label, line]
        if !status.unit.isEmpty {
            let unit = gridLabel(status.unit, size: 13, weight: .medium, color: .secondaryLabelColor)
            let fitsInline = figure.fittingSize.width + line.spacing + unit.fittingSize.width <= width
            if fitsInline { line.addArrangedSubview(unit) } else { views.append(unit) }
        }
        let block = NSStackView(views: views)
        block.orientation = .vertical
        block.alignment = .leading
        block.spacing = 2
        block.widthAnchor.constraint(equalToConstant: width).isActive = true
        return block
    }

    /// "Context ▬▬▬▬▬▬▬▬░░░ 43%" with its detail on a second line under the bar.
    private func usageRow(_ row: UsageRow) -> NSView {
        let label = gridLabel(row.label, size: 12, weight: .medium, color: .labelColor)
        label.widthAnchor.constraint(equalToConstant: USAGE_LABEL_WIDTH).isActive = true
        let bar = TimeBar(track: .quaternaryLabelColor, ink: .labelColor)
        bar.set(fraction: min(max(row.percent / 100, 0), 1), animated: false)
        let percent = gridLabel("\(Int(row.percent.rounded()))%", size: 12, weight: row.isHigh ? .bold : .medium,
                                color: .labelColor)
        percent.alignment = .right
        let percentColumn = NSStackView(views: [percent])
        percentColumn.spacing = 3
        if row.isHigh {
            let warning = NSImageView(image: NSImage(systemSymbolName: "exclamationmark.triangle.fill",
                                                     accessibilityDescription: "High usage") ?? NSImage())
            warning.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 11, weight: .bold)
                .applying(.preferringMulticolor())
            percentColumn.insertArrangedSubview(warning, at: 0)
        }
        percentColumn.widthAnchor.constraint(equalToConstant: USAGE_PERCENT_WIDTH).isActive = true
        let line = NSStackView(views: [label, bar, percentColumn])
        line.alignment = .centerY
        line.spacing = 8
        line.widthAnchor.constraint(equalToConstant: contentWidth).isActive = true
        guard !row.detail.isEmpty else { return line }
        let detail = gridLabel(row.detail, size: 11, weight: .medium, color: .secondaryLabelColor)
        let detailLine = NSStackView(views: [detail])
        detailLine.edgeInsets = NSEdgeInsets(top: 0, left: USAGE_LABEL_WIDTH + 8, bottom: 0, right: 0)
        let block = NSStackView(views: [line, detailLine])
        block.orientation = .vertical
        block.alignment = .leading
        block.spacing = 2
        return block
    }
}
