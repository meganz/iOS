import Foundation

// MARK: - Ordered numbers

extension RichDocument {
    /// The number shown for every block, in one pass. nil for blocks that are not ordered items.
    func orderedNumbers() -> [Int?] {
        Self.orderedNumbers(of: blocks)
    }

    /// A run is the items of one indent with the same kind, between shallower items or other blocks.
    /// It counts up from the start number of its first item, or from 1.
    static func orderedNumbers(of blocks: some Sequence<RichBlock>) -> [Int?] {
        // Per indent: whether the open run is ordered, and the number of its last item.
        var runs: [Int: (isOrdered: Bool, number: Int)] = [:]
        return blocks.map { block in
            guard case .listItem(let item, _) = block else {
                runs.removeAll()
                return nil
            }
            // A shallower item ends every deeper run.
            if runs.keys.contains(where: { $0 > item.indent }) {
                runs = runs.filter { $0.key <= item.indent }
            }
            let number: Int
            if let start = item.startNumber {
                number = start
            } else if let run = runs[item.indent], run.isOrdered == item.isOrdered {
                number = run.number + 1
            } else {
                number = 1
            }
            runs[item.indent] = (item.isOrdered, number)
            return item.isOrdered ? number : nil
        }
    }

    /// The number shown for one ordered item. Walks back to the start of its run only.
    func orderedNumber(at blockIndex: Int) -> Int? {
        guard blocks.indices.contains(blockIndex), case .listItem(let target, _) = blocks[blockIndex], target.isOrdered else { return nil }
        var count = 0
        var start = 1
        var index = blockIndex
        while index >= 0 {
            guard case .listItem(let item, _) = blocks[index] else { break }
            if item.indent > target.indent {
                index -= 1
                continue
            }
            if item.indent < target.indent || item.isOrdered != target.isOrdered { break }
            count += 1
            if let number = item.startNumber {
                start = number
                break
            }
            index -= 1
        }
        return start + count - 1
    }
}
