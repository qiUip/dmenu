import Darwin
import Foundation

// fzy C library interface
@_silgen_name("has_match")
private func fzy_has_match(_ needle: UnsafePointer<Int8>, _ haystack: UnsafePointer<Int8>) -> Int32

@_silgen_name("match")
private func fzy_match(_ needle: UnsafePointer<Int8>, _ haystack: UnsafePointer<Int8>) -> Double

@_silgen_name("match_positions")
private func fzy_match_positions(
	_ needle: UnsafePointer<Int8>, _ haystack: UnsafePointer<Int8>,
	_ positions: UnsafeMutablePointer<size_t>?
) -> Double

extension dmenu {
	/// Check if a needle matches a haystack using fzy algorithm
	func fzyHasMatch(needle: String, haystack: String) -> Bool {
		guard let needlePtr = needle.cString(using: .utf8),
			let haystackPtr = haystack.cString(using: .utf8)
		else {
			return false
		}

		return fzy_has_match(needlePtr, haystackPtr) != 0
	}

	/// Get fzy match score for a needle in haystack
	func fzyMatchScore(needle: String, haystack: String) -> Double? {
		guard let needlePtr = needle.cString(using: .utf8),
			let haystackPtr = haystack.cString(using: .utf8)
		else {
			return nil
		}

		// Check if there's a match first
		guard fzy_has_match(needlePtr, haystackPtr) != 0 else {
			return nil
		}

		let score = fzy_match(needlePtr, haystackPtr)

		// Accept all scores except -INFINITY (including +INFINITY for exact matches)
		return score != -Double.infinity ? score : nil
	}

	/// Get fzy match score and positions for a needle in haystack
	func fzyMatchWithPositions(needle: String, haystack: String) -> (
		score: Double, positions: [Int]
	)? {
		guard let needlePtr = needle.cString(using: .utf8),
			let haystackPtr = haystack.cString(using: .utf8)
		else {
			return nil
		}

		// First check if there's a match at all
		guard fzy_has_match(needlePtr, haystackPtr) != 0 else {
			return nil
		}

		let needleLen = needle.count
		var positions = [size_t](repeating: 0, count: needleLen)

		let score = fzy_match_positions(needlePtr, haystackPtr, &positions)

		// fzy returns INFINITY for perfect matches, -INFINITY for no match
		// Accept anything except -INFINITY (including +INFINITY for exact matches)
		guard score != -Double.infinity else { return nil }

		// Convert UTF-8 byte positions to String character positions
		let utf8View = haystack.utf8
		let characterPositions = positions.compactMap { bytePos -> Int? in
			let utf8Index = utf8View.index(utf8View.startIndex, offsetBy: Int(bytePos))
			guard let charIndex = utf8Index.samePosition(in: haystack) else {
				return nil
			}
			return haystack.distance(from: haystack.startIndex, to: charIndex)
		}

		// Ensure we got valid positions for all matches
		guard characterPositions.count == positions.count else {
			return nil
		}

		return (score, characterPositions)
	}

	/// Get fzy match score and positions for consecutive characters only
	func fzyMatchConsecutiveWithPositions(needle: String, haystack: String) -> (
		score: Double, positions: [Int]
	)? {
		// First get the regular match positions (already converted to character positions)
		guard let (score, positions) = fzyMatchWithPositions(needle: needle, haystack: haystack)
		else {
			return nil
		}

		// Check if the positions are consecutive
		for i in 1..<positions.count {
			if positions[i] != positions[i - 1] + 1 {
				return nil
			}
		}

		return (score, positions)
	}
}
