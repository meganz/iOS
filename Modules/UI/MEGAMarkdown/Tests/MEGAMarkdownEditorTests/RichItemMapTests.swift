@testable import MEGAMarkdownEditor
import Testing

@Suite struct RichItemMapTests {
    /// The item of every row, written out: the slow, obvious answer.
    private func expected(_ counts: [Int]) -> [(row: Int, piece: Int)] {
        counts.enumerated().flatMap { row, count in (0..<max(1, count)).map { (row, $0) } }
    }

    private func expectMatches(_ map: RichItemMap, _ counts: [Int], sourceLocation: SourceLocation = #_sourceLocation) {
        let items = expected(counts)
        #expect(map.rowCount == counts.count, sourceLocation: sourceLocation)
        #expect(map.itemCount == items.count, sourceLocation: sourceLocation)
        for (item, place) in items.enumerated() {
            let found = map.row(forItem: item)
            #expect(found.row == place.row && found.piece == place.piece, "item \(item)", sourceLocation: sourceLocation)
        }
        var first = 0
        for (row, count) in counts.enumerated() {
            #expect(map.items(forRow: row) == first..<(first + max(1, count)), "row \(row)", sourceLocation: sourceLocation)
            first += max(1, count)
        }
    }

    @Test func rowsOfOneItemMapToThemselves() {
        let counts = [1, 1, 1, 1]
        expectMatches(RichItemMap(itemCounts: counts), counts)
    }

    @Test func splitRowsTakeSeveralItems() {
        let counts = [1, 3, 1, 1, 6, 2, 1]
        expectMatches(RichItemMap(itemCounts: counts), counts)
    }

    @Test func emptyRawRowStillTakesOneItem() {
        let counts = [1, 0, 1]
        expectMatches(RichItemMap(itemCounts: counts), counts)
    }

    @Test func replaceReturnsTheOldItems() {
        var map = RichItemMap(itemCounts: [1, 3, 1, 4, 1])
        #expect(map.replaceRows(1..<2, newItemCounts: [1, 1]) == 1..<4)
        expectMatches(map, [1, 1, 1, 1, 4, 1])
        #expect(map.replaceRows(6..<6, newItemCounts: [5]) == 9..<9)
        expectMatches(map, [1, 1, 1, 1, 4, 1, 5])
        #expect(map.replaceRows(0..<4, newItemCounts: []) == 0..<4)
        expectMatches(map, [4, 1, 5])
    }

    /// Random replaces keep the map equal to one built from scratch.
    @Test func randomReplacesMatchARebuild() {
        var generator = SeededGenerator(seed: 7)
        var counts = (0..<40).map { _ in Int.random(in: 0...4, using: &generator) }
        var map = RichItemMap(itemCounts: counts)
        for _ in 0..<300 {
            let lower = Int.random(in: 0...counts.count, using: &generator)
            let upper = Int.random(in: lower...min(counts.count, lower + 5), using: &generator)
            let new = (0..<Int.random(in: 0...5, using: &generator)).map { _ in Int.random(in: 0...4, using: &generator) }
            let oldItems = map.replaceRows(lower..<upper, newItemCounts: new)
            let before = counts[..<lower].reduce(0) { $0 + max(1, $1) }
            #expect(oldItems == before..<(before + counts[lower..<upper].reduce(0) { $0 + max(1, $1) }))
            counts.replaceSubrange(lower..<upper, with: new)
            #expect(map == RichItemMap(itemCounts: counts))
        }
        expectMatches(map, counts)
    }
}
