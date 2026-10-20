import AppKit

// What the break card shows and says: its palette, the step-by-step timing and the stamp it leaves.
// Kept free of views so it's tested without a screen.

// MARK: Palette

/// Swiss red, held back for Done alone: the one thing on the card to press.
let DONE_RED = hex(0xE30613)
let DONE_RED_PRESSED = hex(0xB8000F)

func hex(_ value: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((value >> 16) & 0xFF) / 255, green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255, alpha: 1)
}

/// One colour in Light Mode, another in Dark Mode.
func appearanceColor(light: UInt32, dark: UInt32) -> NSColor {
    NSColor(name: nil) { appearance in
        hex(appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light)
    }
}

let CARD_GROUND = appearanceColor(light: 0xFFFFFF, dark: 0x0B0B0B)
let CARD_INK = appearanceColor(light: 0x0A0A0A, dark: 0xF2F2F2)
let CARD_INK_SECONDARY = appearanceColor(light: 0x5C5C5C, dark: 0xA3A3A3)
let CARD_RULE = appearanceColor(light: 0xE3E3E3, dark: 0x2E2E2E)

extension ExerciseKind {
    var label: String { rawValue.capitalized }

    /// The type's field: one hue at full strength, the same in Light and Dark Mode.
    var field: NSColor {
        switch self {
        case .stretch: hex(0x1D3FD6)
        case .strength: hex(0xFFC400)
        case .move: hex(0x00875A)
        }
    }

    /// Text and figures set on the field.
    var fieldInk: NSColor { self == .strength ? hex(0x0A0A0A) : .white }
}

/// WCAG contrast ratio between two colours, from 1 (none) to 21.
func contrastRatio(_ first: NSColor, _ second: NSColor) -> Double {
    func luminance(_ color: NSColor) -> Double {
        guard let rgb = color.usingColorSpace(.sRGB) else { return 0 }
        func linear(_ component: CGFloat) -> Double {
            let value = Double(component)
            return value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(rgb.redComponent) + 0.7152 * linear(rgb.greenComponent)
            + 0.0722 * linear(rgb.blueComponent)
    }
    let (lighter, darker) = (max(luminance(first), luminance(second)), min(luminance(first), luminance(second)))
    return (lighter + 0.05) / (darker + 0.05)
}

// MARK: Step by step

/// How full each step's time bar is, 0...1: the exercise time split evenly across its tips, in order.
func stepFills(remaining: Int, total: Int, steps: Int) -> [Double] {
    guard steps > 0 else { return [] }
    guard total > 0 else { return Array(repeating: 1, count: steps) }
    let elapsed = Double(min(max(total - remaining, 0), total))
    let share = Double(total) / Double(steps)
    return (0..<steps).map { index in min(max((elapsed - Double(index) * share) / share, 0), 1) }
}

/// The step to do right now, or nil once the time is up.
func currentStep(remaining: Int, total: Int, steps: Int) -> Int? {
    stepFills(remaining: remaining, total: total, steps: steps).firstIndex { $0 < 1 }
}

/// What VoiceOver says for a step: its position and whether it's the one to do now.
func stepAccessibilityLabel(index: Int, count: Int, tip: String, fill: Double, isCurrent: Bool) -> String {
    let state = isCurrent ? ", current" : fill >= 1 ? ", done" : ""
    return "Step \(index + 1) of \(count)\(state): \(tip)"
}

// MARK: Figures

let VISIBLE_ALPHA: UInt8 = 8  // fainter pixels are leftover fringe from removing the green, not the figure

/// The picture cropped to its visible pixels, so a figure with transparent padding stands on the field's edge.
func trimmingTransparentEdges(_ image: NSImage) -> NSImage {
    guard let source = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return image }
    let (width, height) = (source.width, source.height)
    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    let isDrawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
        guard let context = CGContext(data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                                      bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
        context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))
        return true
    }
    guard isDrawn else { return image }
    // Rows run top to bottom in memory, the same way cropping(to:) counts them.
    var (minX, minY, maxX, maxY) = (width, height, -1, -1)
    for y in 0..<height {
        for x in 0..<width where pixels[(y * width + x) * 4 + 3] > VISIBLE_ALPHA {
            (minX, maxX, minY, maxY) = (min(minX, x), max(maxX, x), min(minY, y), max(maxY, y))
        }
    }
    guard maxX >= minX, maxY >= minY,
          let cropped = source.cropping(to: CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1))
    else { return image }
    let scale = image.size.width / CGFloat(width)
    return NSImage(cgImage: cropped, size: NSSize(width: CGFloat(cropped.width) * scale,
                                                  height: CGFloat(cropped.height) * scale))
}

// MARK: Stamps

/// What a card shows for a moment before it leaves: nothing just vanishes.
enum Stamp: Equatable {
    case counted(today: Int, goal: Int)
    case snoozed(until: Date)
    case agentDone(name: String, isWaiting: Bool = false)

    var headline: String {
        switch self {
        case .counted: "Nice!"
        case .snoozed: "Back at"
        case .agentDone(let name, let isWaiting): isWaiting ? "\(name) needs you" : "\(name) is done"
        }
    }

    /// Set at monumental size: today's count, or the time the break comes back. Empty for an agent's finish.
    var figure: String {
        switch self {
        case .counted(let today, _): "\(today)"
        case .snoozed(let until): until.formatted(.dateTime.hour().minute())
        case .agentDone: ""
        }
    }

    var detail: String {
        switch self {
        case .counted(let today, let goal): today >= goal ? "today. Goal reached" : "of \(goal) today"
        case .snoozed: "Snoozed"
        case .agentDone: "Back to work"
        }
    }

    var announcement: String {
        switch self {
        case .counted(let today, _): "\(headline) \(today) \(detail)"
        case .snoozed: "Snoozed. Back at \(figure)"
        case .agentDone: headline
        }
    }

    /// Red only for the break you counted; the others take the exercise's own field, never a bright flash.
    func colors(on kind: ExerciseKind) -> (field: NSColor, ink: NSColor) {
        if case .counted = self { return (DONE_RED, .white) }
        return (kind.field, kind.fieldInk)
    }
}

// MARK: Spoken text

/// What VoiceOver says when a card drops down: the panel never takes focus, so it would otherwise go unnoticed.
func popupAnnouncement(for exercise: Exercise, chipText: String?) -> String {
    let context = chipText ?? (exercise.posture == .standing ? "Stand-up break" : "Seated break")
    return "\(context): \(exercise.name)"
}

func countdownAccessibilityLabel(remaining: Int) -> String {
    switch remaining {
    case ...0: "Time's up"
    case 1: "1 second left"
    default: "\(remaining) seconds left"
    }
}
