import Foundation

/// The rows of one text, kept in parts of one batch each. Rows are only appended.
/// Parts keep an append cheap: one array of a million rows would copy itself each time it grows.
@MainActor
final class PreviewRowStore {
    private var parts: [[PreviewRow]] = []
    /// The index of the first row of each part.
    private var partStarts: [Int] = []
    private(set) var count = 0
    /// Indexes of the notice rows. Their height depends on the preview strings.
    private(set) var noticeRows: [Int] = []

    init(rows: [PreviewRow] = []) {
        append(rows)
    }

    deinit {
        // Freeing a million rows takes long, and the last owner lets go on the main thread. The task frees them elsewhere.
        guard count > 10_000 else { return }
        let parts = parts
        Task(priority: .background) {
            withExtendedLifetime(parts) {}
        }
    }

    var isEmpty: Bool { count == 0 }

    var last: PreviewRow? { parts.last?.last }

    func append(_ rows: [PreviewRow]) {
        guard !rows.isEmpty else { return }
        for (offset, row) in rows.enumerated() {
            if case .notice = row.content { noticeRows.append(count + offset) }
        }
        partStarts.append(count)
        parts.append(rows)
        count += rows.count
    }

    /// O(log parts).
    subscript(index: Int) -> PreviewRow {
        let part = partIndex(containing: index)
        return parts[part][index - partStarts[part]]
    }

    /// The index of the row that contains `line`: the last row that starts at or before it.
    /// Rows are in source order, so this is a binary search. Nil when there are no rows.
    func rowIndex(containing line: Int) -> Int? {
        guard count > 0 else { return nil }
        var low = 0
        var high = count
        while low < high {
            let middle = (low + high) / 2
            if self[middle].sourceLine <= line { low = middle + 1 } else { high = middle }
        }
        return max(low - 1, 0)
    }

    /// The last part whose first row is at or before `index`.
    private func partIndex(containing index: Int) -> Int {
        var low = 0
        var high = partStarts.count
        while low < high {
            let middle = (low + high) / 2
            if partStarts[middle] <= index { low = middle + 1 } else { high = middle }
        }
        return max(low - 1, 0)
    }
}
