import Cocoa

final class row: NSTableRowView {
	var colors: color_scheme!

	override func drawSelection(in _: NSRect) {
		guard selectionHighlightStyle != .none else { return }
		let rect = bounds.insetBy(dx: 2, dy: 2)
		let path = NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6)

		colors.highlight.withAlphaComponent(0.25).setFill()
		path.fill()

		colors.highlight.withAlphaComponent(0.4).setStroke()
		path.lineWidth = 1.0
		path.stroke()
	}
}
