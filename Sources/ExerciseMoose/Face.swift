import AppKit

// Calibration knobs: where your character's head sits in character.png (fractions of the image).
// Re-tune these if you swap in a different character picture.
let FACE_CENTER_X: CGFloat = 0.48
let FACE_CENTER_FROM_TOP: CGFloat = 0.15
let FACE_SIZE: CGFloat = 0.32  // crop side as a fraction of the image width: hair to chin plus a little air
let MENU_BAR_FACE_SIZE: CGFloat = 18
let ICON_PIXELS = 1024
let ICON_INSET_RATIO: CGFloat = 0.1  // macOS icons leave a margin around the rounded square
let ICON_CORNER_RATIO: CGFloat = 0.225
let ICON_CROP_SCALE: CGFloat = 1.2  // head and shoulders for the app icon

struct IconError: Error, CustomStringConvertible {
    let description: String
}

/// Square crop around the head; `scale` > 1 widens it, growing downward toward the shoulders.
func faceCrop(in size: NSSize, scale: CGFloat) -> NSRect {
    let side = size.width * FACE_SIZE * scale
    let centerY = size.height * (1 - FACE_CENTER_FROM_TOP) - (side - size.width * FACE_SIZE) / 2  // image coords are y-up
    return NSRect(x: size.width * FACE_CENTER_X - side / 2, y: centerY - side / 2, width: side, height: side)
}

/// The moose silhouette bundled by build.sh, as a template image so macOS tints it for light and dark menu bars.
func bundledMenuBarIcon() -> NSImage? {
    guard let url = Bundle.main.url(forResource: "MenuBarIcon", withExtension: "png"),
          let image = NSImage(contentsOf: url) else { return nil }
    image.size = NSSize(width: MENU_BAR_FACE_SIZE, height: MENU_BAR_FACE_SIZE)
    image.isTemplate = true
    return image
}

/// Your character's face in a circle of the stretch field's colour, for the menu bar.
func menuBarFace() -> NSImage? {
    guard let character = NSImage(contentsOf: characterImageURL()) else { return nil }
    let size = NSSize(width: MENU_BAR_FACE_SIZE, height: MENU_BAR_FACE_SIZE)
    return NSImage(size: size, flipped: false) { rect in
        let circle = NSBezierPath(ovalIn: rect)
        ExerciseKind.stretch.field.setFill()
        circle.fill()
        circle.addClip()
        character.draw(in: rect, from: faceCrop(in: character.size, scale: 1), operation: .sourceOver, fraction: 1)
        return true
    }
}

/// Writes a 1024px app icon: your character on the stretch field. Used by build.sh.
func writeAppIcon(to url: URL) throws {
    guard let character = NSImage(contentsOf: characterImageURL()) else {
        throw IconError(description: "no character.png yet; run ./convert.sh first")
    }
    guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: ICON_PIXELS, pixelsHigh: ICON_PIXELS,
                                        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) else {
        throw IconError(description: "could not create the icon bitmap")
    }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let canvas = CGFloat(ICON_PIXELS)
    let tile = NSRect(x: 0, y: 0, width: canvas, height: canvas).insetBy(dx: canvas * ICON_INSET_RATIO,
                                                                         dy: canvas * ICON_INSET_RATIO)
    let shape = NSBezierPath(roundedRect: tile, xRadius: tile.width * ICON_CORNER_RATIO,
                             yRadius: tile.width * ICON_CORNER_RATIO)
    ExerciseKind.stretch.field.setFill()
    shape.fill()
    shape.addClip()
    character.draw(in: tile, from: faceCrop(in: character.size, scale: ICON_CROP_SCALE),
                   operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        throw IconError(description: "could not encode the icon as PNG")
    }
    try png.write(to: url)
}
