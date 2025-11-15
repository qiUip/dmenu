import Cocoa
import QuartzCore

extension dmenu {
	func buildUI() {
		let screen = NSScreen.main!.frame
		let width = config.width
		let height = config.totalHeight
		let borderRadius = config.borderRadius
		let searchH = config.lock ? 0 : config.searchH
		let itemH = config.itemH
		let searchFieldH = config.searchFieldHeight
		let sidePadding = config.sidePadding
		let iconSize = config.iconSize

		window = NSWindow(
			contentRect: NSRect(
				x: (screen.width - width) / 2,
				y: (screen.height - height) / 2,
				width: width,
				height: height
			),
			styleMask: [.titled, .fullSizeContentView, .borderless],
			backing: .buffered,
			defer: false
		)

		window.isOpaque = false
		window.backgroundColor = .clear
		window.hasShadow = false
		window.level = .floating
		window.titleVisibility = .hidden
		window.titlebarAppearsTransparent = true
		window.isMovableByWindowBackground = false

		NSApp.setActivationPolicy(.accessory)
		window.center()
		window.makeKeyAndOrderFront(nil)

		let rootBlur = NSVisualEffectView(frame: window.contentView!.bounds)
		rootBlur.autoresizingMask = [.width, .height]
		rootBlur.material = .hudWindow
		rootBlur.blendingMode = .behindWindow
		rootBlur.state = .active
		rootBlur.wantsLayer = true
		rootBlur.layer?.cornerRadius = borderRadius
		rootBlur.layer?.masksToBounds = false
		window.contentView = rootBlur

		let shadowLayer = CALayer()
		shadowLayer.frame = rootBlur.bounds
		shadowLayer.cornerRadius = borderRadius
		shadowLayer.backgroundColor = config.colors.background.withAlphaComponent(0.5).cgColor
		rootBlur.layer?.addSublayer(shadowLayer)
		if !config.lock {
			let searchAreaTopY = height - searchH
			let searchAreaCenterY = searchAreaTopY + searchH / 2
			let ySearch = searchAreaCenterY - searchFieldH / 2 - 4
			let leadingX: CGFloat = config.showIcon ? config.iconPadding : config.textPadding

			if config.showIcon {
				let iconY = searchAreaCenterY - iconSize / 2
				let iconX = (config.iconPadding - iconSize) / 2

				let iconView = NSImageView(
					frame: .init(x: iconX, y: iconY, width: iconSize, height: iconSize))
				iconView.image = NSImage(
					systemSymbolName: "magnifyingglass", accessibilityDescription: nil
				)?
				.withSymbolConfiguration(.init(pointSize: iconSize, weight: .light))
				iconView.contentTintColor = .secondaryLabelColor
				rootBlur.addSubview(iconView)
			}

			searchField = searchfield(
				frame: .init(
					x: leadingX,
					y: ySearch,
					width: width - leadingX - config.textPadding,
					height: searchFieldH
				))
			searchField.fontName = config.fontName
			searchField.itemFontSize = config.searchFontSize
			searchField.customTextColor = config.colors.text
			searchField.placeholderString = config.placeholder
			searchField.focusRingType = .none
			searchField.delegate = self
			(searchField.cell as? NSSearchFieldCell)?.font = NSFont.preferred(
				named: config.fontName, size: config.searchFontSize, weight: .regular)

			searchField.isBordered = false
			searchField.drawsBackground = false
			searchField.wantsLayer = true
			if let cell = searchField.cell as? NSSearchFieldCell {
				cell.searchButtonCell = nil
				cell.cancelButtonCell = nil
			}
			rootBlur.addSubview(searchField)

			let sep = NSView(
				frame: .init(
					x: 0,
					y: height - searchH,
					width: width,
					height: 1
				))
			sep.wantsLayer = true
			sep.layer?.backgroundColor = NSColor.separatorColor.withAlphaComponent(0.07).cgColor
			sep.autoresizingMask = [.width]
			rootBlur.addSubview(sep)
		}

		let scroll = NSScrollView(
			frame: .init(
				x: sidePadding,
				y: 0,
				width: width - sidePadding,
				height: height - searchH
			))
		scroll.drawsBackground = false
		scroll.hasVerticalScroller = true
		scroll.scrollerStyle = .overlay
		scroll.automaticallyAdjustsContentInsets = false
		scroll.autohidesScrollers = false
		scroll.scrollerKnobStyle = .light

		let custom = scroller(frame: .zero)
		custom.padding = sidePadding
		custom.scrollerStyle = .overlay
		scroll.verticalScroller = custom

		tableView = NSTableView(
			frame: scroll.frame)
		tableView.autoresizingMask = [.width, .height]
		tableView.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
		tableView.headerView = nil
		tableView.rowHeight = itemH
		tableView.backgroundColor = .clear
		tableView.selectionHighlightStyle = .regular
		tableView.delegate = self
		tableView.dataSource = self

		let col = NSTableColumn(identifier: .init("Item"))
		col.resizingMask = .autoresizingMask
		tableView.addTableColumn(col)

		scroll.documentView = tableView
		rootBlur.addSubview(scroll)
	}
}
