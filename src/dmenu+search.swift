import Cocoa

extension dmenu {
	func loadStdin() {
		guard
			let data = try? FileHandle.standardInput.readToEnd(),
			let str = String(data: data, encoding: .utf8)
		else { return }

		allItems = str.split(separator: "\n").map(String.init)
		allItemsLower = allItems.map { $0.lowercased() }
		allIndices = Array(allItems.indices)
		filteredItems = allItems
		liveIndices = allIndices

		tableView.reloadData()
		selectRow(index: 0)
	}

	func controlTextDidChange(_: Notification) {
		guard !config.lock else { return }

		guard let searchField = searchField else { return }

		let tokens = searchField.stringValue
			.lowercased()
			.split(whereSeparator: \.isWhitespace)

		currentTokens = Array(tokens)

		guard !tokens.isEmpty else {
			filteredItems = allItems
			liveIndices = allIndices
			matchPositions.removeAll()
			lastTokens = []
			tableView.reloadData()
			if !filteredItems.isEmpty { selectRow(index: 0) }
			return
		}

		// Always search all indices to avoid race conditions
		// TODO: Re-implement incremental search with proper synchronization
		let currentSearch = tokens.joined(separator: " ")
		let searchSpace = allIndices

		Self.workQ.async {
			let needle = currentSearch
			var best = [(score: Double, idx: Int)]()
			best.reserveCapacity(128)
			var newMatchPositions: [Int: [Int]] = [:]

			for idx in searchSpace {
				let haystack = self.allItemsLower[idx]

				let matchResult: (score: Double, positions: [Int])?
				if self.config.consecutiveOnly {
					matchResult = self.fzyMatchConsecutiveWithPositions(
						needle: needle, haystack: haystack)
				} else {
					matchResult = self.fzyMatchWithPositions(needle: needle, haystack: haystack)
				}

				if let (score, positions) = matchResult {
					best.append((score, idx))
					newMatchPositions[idx] = positions

					if best.count > 128 {
						best.sort(by: { $0.score > $1.score })
						best.removeLast(best.count - 128)
					}
				}
			}

			best.sort(by: { $0.score > $1.score })

			let newLive = best.map { $0.idx }
			let newItems = newLive.map { self.allItems[$0] }

			DispatchQueue.main.async {
				self.liveIndices = newLive
				self.filteredItems = newItems
				self.matchPositions = newMatchPositions
				self.lastTokens = tokens

				self.tableView.beginUpdates()
				self.tableView.reloadData()
				self.tableView.endUpdates()

				if !newItems.isEmpty {
					self.selectRow(index: 0)

					// Add auto-select logic here
					if self.config.autoSelect && newItems.count == 1 {
						self.selectCurrentRow()
					}
				}
			}
		}
	}

	func installKeyMonitor() {
		NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] e in
			guard let self = self else { return e }

			switch e.keyCode {
			case 126:
				self.moveSelection(offset: -1)
				return nil
			case 125:
				self.moveSelection(offset: 1)
				return nil
			case 35 where e.modifierFlags.contains(.control):
				self.moveSelection(offset: -1)
				return nil
			case 45 where e.modifierFlags.contains(.control):
				self.moveSelection(offset: 1)
				return nil
			case 36:
				self.selectCurrentRow()
				return nil
			case 8 where e.modifierFlags.contains(.control), 53:
				self.closeWindow()
				return nil
			default: return e
			}
		}
	}
}
