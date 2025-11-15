import Cocoa
import Darwin

// fzy C library interface for highlighting
@_silgen_name("match_positions")
private func fzy_match_positions(
	_ needle: UnsafePointer<Int8>, _ haystack: UnsafePointer<Int8>,
	_ positions: UnsafeMutablePointer<size_t>?
) -> Double

final class textfield: NSTextField {
	var itemFontSize: CGFloat!
	var fontName: String?
	var customTextColor: NSColor!
	var highlightColor: NSColor!

	override var allowsVibrancy: Bool { false }

	override var stringValue: String {
		didSet {
			if oldValue != stringValue {
				applyBaseAttributes()
			}
		}
	}

	override var attributedStringValue: NSAttributedString {
		didSet {}
	}

	private func applyBaseAttributes() {
		guard !stringValue.isEmpty else { return }

		let baseFont = NSFont.preferred(named: fontName, size: itemFontSize, weight: .regular)

		let attr = NSMutableAttributedString(string: stringValue)

		attr.addAttributes(
			[
				.font: baseFont,
				.foregroundColor: customTextColor!,
				.kern: 0.5,
			], range: NSRange(location: 0, length: stringValue.count)
		)

		super.attributedStringValue = attr
	}

	// Highlight with pre-computed positions (no fzy call)
	func highlight(item: String, positions: [Int]) -> NSAttributedString {
		let attr = NSMutableAttributedString(string: item)
		let baseFont = NSFont.preferred(named: fontName, size: itemFontSize, weight: .regular)

		// Apply base attributes
		attr.addAttributes(
			[
				.font: baseFont,
				.foregroundColor: customTextColor!,
				.kern: 0.5,
			], range: NSRange(location: 0, length: item.count)
		)

		// Highlight matched positions
		for position in positions {
			// Ensure position is within bounds, convert character offset to string index
			guard position >= 0,
				let charIndex = item.index(
					item.startIndex, offsetBy: position, limitedBy: item.endIndex),
				charIndex < item.endIndex
			else {
				continue
			}

			// Create a range for the character at the given index
			let range = NSRange(charIndex..<item.index(after: charIndex), in: item)
			attr.addAttributes(
				[
					.backgroundColor: highlightColor.withAlphaComponent(0.2),
					.font: NSFont.preferred(
						named: fontName,
						size: itemFontSize, weight: .bold
					),
					.foregroundColor: highlightColor!,
					.kern: 0.8,
					.shadow: {
						let shadow = NSShadow()
						shadow.shadowColor = highlightColor.withAlphaComponent(0.7)
						shadow.shadowOffset = NSSize(width: 0, height: 0)
						shadow.shadowBlurRadius = 3.0
						return shadow
					}(),
				], range: range
			)
		}

		return attr
	}
}
