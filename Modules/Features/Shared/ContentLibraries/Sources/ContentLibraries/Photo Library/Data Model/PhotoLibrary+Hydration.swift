import MEGADomain

public extension PhotoLibrary {
    /// Replace the item at each given flat index with its supplied node, preserving the tree
    /// structure — section shape and total count are unchanged, only leaves swap. Indices
    /// outside the tree are ignored. One traversal regardless of how many splices, so a window
    /// made of several placeholder runs is hydrated in a single pass.
    ///
    /// Only the day buckets a replacement lands in are rebuilt; every other day, month and year is
    /// carried over as-is, so its `contentList` keeps sharing storage with the receiver. Hydrating a
    /// window therefore costs the nodes in its own days plus one walk of the tree spine, not a copy
    /// of the whole library.
    func replacingPhotos(at replacements: [Int: NodeEntity]) -> PhotoLibrary {
        guard !replacements.isEmpty else { return self }
        var splicer = PhotoSplicer(replacements)
        return PhotoLibrary(photoByYearList: splicer.splicing(photoByYearList))
    }

    /// Convenience over `replacingPhotos(at:)` for one contiguous run starting at `startIndex`.
    func replacingPhotos(from startIndex: Int, with replacements: [NodeEntity]) -> PhotoLibrary {
        guard !replacements.isEmpty, startIndex >= 0 else { return self }
        let indexed = replacements.enumerated().map { (startIndex + $0.offset, $0.element) }
        return replacingPhotos(at: Dictionary(uniqueKeysWithValues: indexed))
    }
}

/// Walks a library's leaves in flat order and rebuilds only the branches a replacement lands in.
/// Each level answers `nil` for "nothing changed here", which lets its parent hand back its own
/// node untouched so the whole branch keeps sharing storage with the original tree.
private struct PhotoSplicer {
    private let replacements: [Int: NodeEntity]
    /// Replacement indices in ascending order, so a single forward cursor can answer "does anything
    /// land in this bucket?" for every bucket in one walk.
    private let targets: [Int]
    private var cursor = 0
    private var flatIndex = 0

    init(_ replacements: [Int: NodeEntity]) {
        self.replacements = replacements
        targets = replacements.keys.sorted()
    }

    mutating func splicing(_ years: [PhotoByYear]) -> [PhotoByYear] {
        var didChange = false
        let spliced = years.map { year -> PhotoByYear in
            guard let months = splicing(year.contentList) else { return year }
            didChange = true
            return PhotoByYear(categoryDate: year.categoryDate, contentList: months)
        }
        return didChange ? spliced : years
    }

    private mutating func splicing(_ months: [PhotoByMonth]) -> [PhotoByMonth]? {
        var didChange = false
        let spliced = months.map { month -> PhotoByMonth in
            guard let days = splicing(month.contentList) else { return month }
            didChange = true
            return PhotoByMonth(categoryDate: month.categoryDate, contentList: days)
        }
        return didChange ? spliced : nil
    }

    private mutating func splicing(_ days: [PhotoByDay]) -> [PhotoByDay]? {
        var didChange = false
        let spliced = days.map { day -> PhotoByDay in
            guard let nodes = splicing(day.contentList) else { return day }
            didChange = true
            return PhotoByDay(categoryDate: day.categoryDate, contentList: nodes)
        }
        return didChange ? spliced : nil
    }

    private mutating func splicing(_ nodes: [NodeEntity]) -> [NodeEntity]? {
        let start = flatIndex
        flatIndex += nodes.count
        // Drop the targets before this bucket: out-of-range negatives on the first bucket, already
        // applied ones afterwards. Buckets are visited in ascending flat order, so this never rewinds.
        while cursor < targets.endIndex, targets[cursor] < start { cursor += 1 }
        guard cursor < targets.endIndex, targets[cursor] < flatIndex else { return nil }
        return nodes.enumerated().map { replacements[start + $0.offset] ?? $0.element }
    }
}
