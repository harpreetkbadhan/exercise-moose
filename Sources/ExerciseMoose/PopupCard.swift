import AppKit

// The break card, set like a Swiss poster: your figure on a full-strength field, one monumental countdown,
// and the exercise's tips as grid columns whose time bars fill one after another.

let CARD_PADDING: CGFloat = 16
let CARD_RADIUS: CGFloat = 12
let FIELD_INSET: CGFloat = 12
let STEP_GAP: CGFloat = 12
let STEP_BAR_HEIGHT: CGFloat = 3
let DONE_WIDTH: CGFloat = 116
let DONE_HEIGHT: CGFloat = 44
let COUNTDOWN_SCALE: CGFloat = 0.42  // of the field's height
let STAMP_FIGURE_SCALE: CGFloat = 0.9  // of the field's height, before fitting the width
let MAX_TIP_LINES = 3
let STEP_NUMBER_SIZE: CGFloat = 15  // the columns' anchors
let MEDIA_HEADROOM: CGFloat = 40  // the reason label's band at the top of the field

extension PopupSize {
    var contentWidth: CGFloat { width - 2 * CARD_PADDING }

    /// The figure stands on the field's bottom edge, left of the countdown, with the reason label clear above its head.
    var mediaSize: NSSize { NSSize(width: (contentWidth * 0.62).rounded(), height: fieldHeight - MEDIA_HEADROOM) }

    var titleSize: CGFloat {
        switch self {
        case .small: 26
        case .medium: 30
        case .large: 34
        }
    }
}

/// Helvetica Neue, the grid's one family.
func gridFont(_ size: CGFloat, _ weight: NSFont.Weight) -> NSFont {
    let name = weight >= .bold ? "HelveticaNeue-Bold" : weight >= .medium ? "HelveticaNeue-Medium" : "HelveticaNeue"
    return NSFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: weight)
}

/// Display sizes are set tight, the way a poster's would be: tracking in proportion to the size.
func gridText(_ text: String, size: CGFloat, weight: NSFont.Weight, color: NSColor, tracking: CGFloat = 0) -> NSAttributedString {
    NSAttributedString(string: text, attributes: [.font: gridFont(size, weight), .foregroundColor: color,
                                                  .kern: size * tracking])
}

func gridLabel(_ text: String, size: CGFloat, weight: NSFont.Weight, color: NSColor, tracking: CGFloat = 0) -> NSTextField {
    let label = NSTextField(labelWithAttributedString: gridText(text, size: size, weight: weight, color: color,
                                                                tracking: tracking))
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
}

/// The largest size up to `maxSize` at which `text` fits `width` on one line.
func fittingFontSize(_ text: String, maxSize: CGFloat, width: CGFloat, tracking: CGFloat) -> CGFloat {
    let measured = gridText(text, size: maxSize, weight: .bold, color: .black, tracking: tracking).size().width
    return measured > width ? (maxSize * width / measured).rounded(.down) : maxSize
}

/// Speaks `text` through VoiceOver without moving focus.
func announce(_ text: String) {
    NSAccessibility.post(element: NSApp as Any, notification: .announcementRequested,
                         userInfo: [.announcement: text, .priority: NSAccessibilityPriorityLevel.high.rawValue])
}

/// A view filled with one colour, kept right when Light and Dark Mode switch.
class FillView: NSView {
    var fill: NSColor { didSet { needsDisplay = true } }

    init(_ fill: NSColor) {
        self.fill = fill
        super.init(frame: .zero)
        wantsLayer = true
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) { nil }

    override var wantsUpdateLayer: Bool { true }

    override func updateLayer() {
        layer?.backgroundColor = fill.cgColor
    }
}

/// A step's time bar: a hairline track that fills in ink while its step is current. The menu passes its own
/// label colours, which read on the menu's material where the card's would not.
final class TimeBar: FillView {
    private let fillLayer = CALayer()
    private let ink: NSColor
    private var fraction = 0.0

    init(track: NSColor = CARD_RULE, ink: NSColor = CARD_INK) {
        self.ink = ink
        super.init(track)
        layer?.addSublayer(fillLayer)
        heightAnchor.constraint(equalToConstant: STEP_BAR_HEIGHT).isActive = true
    }

    required init?(coder: NSCoder) { nil }

    override func updateLayer() {
        super.updateLayer()
        fillLayer.backgroundColor = ink.cgColor
    }

    override func layout() {
        super.layout()
        place(animated: false)
    }

    /// Animated over one second, linear, so per-second updates read as one continuous fill.
    func set(fraction: Double, animated: Bool) {
        self.fraction = fraction
        place(animated: animated)
    }

    private func place(animated: Bool) {
        CATransaction.begin()
        if animated {
            CATransaction.setAnimationDuration(1)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .linear))
        } else {
            CATransaction.setDisableActions(true)
        }
        fillLayer.frame = CGRect(x: 0, y: 0, width: bounds.width * fraction, height: bounds.height)
        CATransaction.commit()
    }
}

/// One tip as a grid column: its number, its words, its time bar. Only the current step is set bold in ink.
final class StepColumn: NSView {
    let bar = TimeBar()
    private let words: NSTextField
    private let index: Int
    private let count: Int
    private let tip: String

    init(index: Int, count: Int, tip: String, width: CGFloat) {
        (self.index, self.count, self.tip) = (index, count, tip)
        let number = gridLabel("\(index + 1)", size: STEP_NUMBER_SIZE, weight: .bold, color: CARD_INK)
        words = NSTextField(wrappingLabelWithString: tip)
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        words.translatesAutoresizingMaskIntoConstraints = false
        words.maximumNumberOfLines = MAX_TIP_LINES
        words.preferredMaxLayoutWidth = width
        // Measured in bold, so turning a step bold never reflows the card mid-break.
        words.font = gridFont(13, .bold)
        let boldHeight = words.fittingSize.height
        number.setAccessibilityElement(false)
        for view in [number, words, bar] { addSubview(view) }
        let tight = bar.topAnchor.constraint(equalTo: words.bottomAnchor, constant: 8)
        tight.priority = .defaultLow
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: width),
            number.topAnchor.constraint(equalTo: topAnchor),
            number.leadingAnchor.constraint(equalTo: leadingAnchor),
            words.topAnchor.constraint(equalTo: number.bottomAnchor, constant: 3),
            words.leadingAnchor.constraint(equalTo: leadingAnchor),
            words.trailingAnchor.constraint(equalTo: trailingAnchor),
            words.heightAnchor.constraint(equalToConstant: boldHeight),
            bar.topAnchor.constraint(greaterThanOrEqualTo: words.bottomAnchor, constant: 8),
            tight,
            bar.leadingAnchor.constraint(equalTo: leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: trailingAnchor),
            bar.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        set(fill: 0, isCurrent: index == 0, animated: false)
    }

    required init?(coder: NSCoder) { nil }

    func set(fill: Double, isCurrent: Bool, animated: Bool) {
        words.font = gridFont(13, isCurrent ? .bold : .medium)
        words.textColor = isCurrent ? CARD_INK : CARD_INK_SECONDARY
        words.setAccessibilityLabel(stepAccessibilityLabel(index: index, count: count, tip: tip, fill: fill,
                                                           isCurrent: isCurrent))
        bar.set(fraction: fill, animated: animated)
    }
}

/// The full-strength field: your figure standing on its bottom edge, the reason top-left, the countdown top-right.
final class FieldView: FillView {
    private let countdown: NSTextField
    private let unit: NSTextField
    private let ink: NSColor
    private let numeralSize: CGFloat

    init(kind: ExerciseKind, reason: String, media: NSView, size: PopupSize) {
        ink = kind.fieldInk
        numeralSize = (size.fieldHeight * COUNTDOWN_SCALE).rounded()
        countdown = gridLabel("", size: numeralSize, weight: .bold, color: kind.fieldInk, tracking: -0.04)
        unit = gridLabel("seconds", size: 12, weight: .bold, color: kind.fieldInk)
        let label = gridLabel(reason, size: 12, weight: .bold, color: kind.fieldInk)
        super.init(kind.field)
        countdown.alignment = .right
        unit.setAccessibilityElement(false)
        for view in [media, label, countdown, unit] {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: size.fieldHeight),
            media.leadingAnchor.constraint(equalTo: leadingAnchor),
            media.bottomAnchor.constraint(equalTo: bottomAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: FIELD_INSET),
            label.firstBaselineAnchor.constraint(equalTo: topAnchor, constant: FIELD_INSET + 10),
            countdown.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -FIELD_INSET + 2),
            countdown.firstBaselineAnchor.constraint(equalTo: topAnchor,
                                                     constant: FIELD_INSET + gridFont(numeralSize, .bold).capHeight),
            unit.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -FIELD_INSET),
            unit.firstBaselineAnchor.constraint(equalTo: countdown.firstBaselineAnchor, constant: 18),
        ])
    }

    required init?(coder: NSCoder) { nil }

    func set(remaining: Int) {
        countdown.attributedStringValue = gridText("\(max(remaining, 0))", size: numeralSize, weight: .bold,
                                                   color: ink, tracking: -0.04)
        unit.attributedStringValue = gridText(remaining > 0 ? "seconds" : "time's up", size: 12, weight: .bold,
                                              color: ink)
        countdown.setAccessibilityLabel(countdownAccessibilityLabel(remaining: remaining))
    }
}

/// The one red thing on the card, and the one thing to press.
final class DoneButton: NSButton {
    override var isHighlighted: Bool {
        didSet { layer?.backgroundColor = (isHighlighted ? DONE_RED_PRESSED : DONE_RED).cgColor }
    }
}

/// The card: field, exercise name, step columns, then Snooze and Done.
final class PopupCard: FillView {
    private let field: FieldView
    private let columns: [StepColumn]
    private let size: PopupSize
    private let kind: ExerciseKind
    private var hasShownTime = false

    /// `chipText` names why an agent or limit break appeared; by default the field says the posture and type.
    init(exercise: Exercise, media: NSView, size: PopupSize, chipText: String?, snoozeMinutes: Int,
         target: AnyObject, doneAction: Selector, snoozeAction: Selector) {
        self.size = size
        let posture = exercise.posture == .standing ? "Stand up" : "Seated"
        field = FieldView(kind: exercise.kind, reason: chipText ?? "\(posture) · \(exercise.kind.label)", media: media,
                          size: size)
        let count = CGFloat(max(exercise.tips.count, 1))
        let columnWidth = ((size.contentWidth - STEP_GAP * (count - 1)) / count).rounded(.down)
        columns = exercise.tips.enumerated().map {
            StepColumn(index: $0.offset, count: exercise.tips.count, tip: $0.element, width: columnWidth)
        }
        kind = exercise.kind
        super.init(CARD_GROUND)
        layer?.cornerRadius = CARD_RADIUS
        layer?.masksToBounds = true

        let title = gridLabel(exercise.name, size: size.titleSize, weight: .bold, color: CARD_INK, tracking: -0.02)
        title.lineBreakMode = .byTruncatingTail
        let steps = NSStackView(views: columns)
        steps.orientation = .horizontal
        steps.alignment = .top
        steps.spacing = STEP_GAP
        for column in columns.dropFirst() {
            column.heightAnchor.constraint(equalTo: columns[0].heightAnchor).isActive = true
        }
        let footer = NSStackView(views: [snoozeButton(minutes: snoozeMinutes, target: target, action: snoozeAction),
                                         doneButton(target: target, action: doneAction)])
        footer.distribution = .equalSpacing
        let stack = NSStackView(views: [field, title, steps, footer])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 0
        stack.setCustomSpacing(14, after: field)
        stack.setCustomSpacing(12, after: title)
        stack.setCustomSpacing(16, after: steps)
        stack.edgeInsets = NSEdgeInsets(top: CARD_PADDING, left: CARD_PADDING, bottom: CARD_PADDING, right: CARD_PADDING)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            widthAnchor.constraint(equalToConstant: size.width),
            field.widthAnchor.constraint(equalToConstant: size.contentWidth),
            title.widthAnchor.constraint(lessThanOrEqualToConstant: size.contentWidth),
            footer.widthAnchor.constraint(equalToConstant: size.contentWidth),
        ])
    }

    required init?(coder: NSCoder) { nil }

    /// The countdown and the step bars; after the first update, bars fill smoothly unless Reduce Motion is on.
    func setRemaining(_ remaining: Int, total: Int) {
        field.set(remaining: remaining)
        let fills = stepFills(remaining: remaining, total: total, steps: columns.count)
        let current = currentStep(remaining: remaining, total: total, steps: columns.count)
        let animated = hasShownTime && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        for (index, column) in columns.enumerated() {
            column.set(fill: fills[index], isCurrent: index == current, animated: animated)
        }
        hasShownTime = true
    }

    /// Covers the card with what just happened before it leaves, set like a poster: the headline at the top,
    /// the monumental figure standing on the detail line at the bottom. It also swallows clicks so Done counts once.
    func stamp(_ stamp: Stamp) {
        let colors = stamp.colors(on: kind)
        let overlay = FillView(colors.field)
        let headline = gridLabel(stamp.headline, size: 17, weight: .bold, color: colors.ink)
        let detail = gridLabel(stamp.detail, size: 17, weight: .bold, color: colors.ink)
        let figure = stampFigure(stamp, ink: colors.ink)
        for view in [headline, figure.view, detail] { overlay.addSubview(view) }
        addSubview(overlay)
        let inset = CARD_PADDING + FIELD_INSET
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: topAnchor),
            overlay.bottomAnchor.constraint(equalTo: bottomAnchor),
            overlay.leadingAnchor.constraint(equalTo: leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: trailingAnchor),
            headline.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: inset),
            headline.firstBaselineAnchor.constraint(equalTo: overlay.topAnchor, constant: inset + 14),
            detail.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: inset),
            detail.lastBaselineAnchor.constraint(equalTo: overlay.bottomAnchor, constant: -inset),
        ] + figure.constraints(inset, detail))
        // A hard cut, like a print changing over: no fade, nothing for Reduce Motion to soften.
        announce(stamp.announcement)
    }

    /// The stamp's monumental figure, and how it sits on the detail line: a number by its baseline (pulled left by
    /// the numeral's side bearing so it aligns optically), a checkmark by its box.
    private func stampFigure(_ stamp: Stamp, ink: NSColor)
        -> (view: NSView, constraints: (CGFloat, NSView) -> [NSLayoutConstraint]) {
        let maxSize = (size.fieldHeight * STAMP_FIGURE_SCALE).rounded()
        guard !stamp.figure.isEmpty else {
            let side = (maxSize * 0.5).rounded()
            let check = NSImageView()
            check.image = NSImage(systemSymbolName: "checkmark", accessibilityDescription: nil)?
                .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: side * 0.8, weight: .heavy)
                    .applying(NSImage.SymbolConfiguration(paletteColors: [ink])))
            check.imageAlignment = .alignBottomLeft
            check.translatesAutoresizingMaskIntoConstraints = false
            return (check, { inset, detail in [
                check.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: inset),
                check.bottomAnchor.constraint(equalTo: detail.topAnchor, constant: -16),
                check.widthAnchor.constraint(equalToConstant: side),
                check.heightAnchor.constraint(equalToConstant: side),
            ] })
        }
        // A single numeral can be set tight; a time like 21:45 needs room or its digits touch.
        let tracking: CGFloat = stamp.figure.count > 1 ? -0.02 : -0.04
        let figureSize = fittingFontSize(stamp.figure, maxSize: maxSize, width: size.contentWidth - 2 * FIELD_INSET,
                                         tracking: tracking)
        let figure = gridLabel(stamp.figure, size: figureSize, weight: .bold, color: ink, tracking: tracking)
        return (figure, { inset, detail in [
            figure.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: inset - figureSize * 0.045),
            figure.lastBaselineAnchor.constraint(equalTo: detail.firstBaselineAnchor, constant: -30),
        ] })
    }

    /// Sharp-edged red block, no Return shortcut: typing Enter in another app must not count a break.
    private func doneButton(target: AnyObject, action: Selector) -> NSButton {
        let button = DoneButton(title: "", target: target, action: action)
        button.isBordered = false
        let centered = NSMutableParagraphStyle()
        centered.alignment = .center
        button.attributedTitle = NSAttributedString(string: "Done", attributes: [
            .font: gridFont(15, .bold), .foregroundColor: NSColor.white, .paragraphStyle: centered,
        ])
        button.wantsLayer = true
        button.layer?.backgroundColor = DONE_RED.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: DONE_WIDTH),
            button.heightAnchor.constraint(equalToConstant: DONE_HEIGHT),
        ])
        return button
    }

    /// As tall as Done, so the quieter action is just as easy to hit.
    private func snoozeButton(minutes: Int, target: AnyObject, action: Selector) -> NSButton {
        let button = NSButton(title: "Snooze \(minutes) min", target: target, action: action)
        button.isBordered = false
        button.font = gridFont(13, .medium)
        button.contentTintColor = CARD_INK_SECONDARY
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: DONE_HEIGHT).isActive = true
        return button
    }
}
