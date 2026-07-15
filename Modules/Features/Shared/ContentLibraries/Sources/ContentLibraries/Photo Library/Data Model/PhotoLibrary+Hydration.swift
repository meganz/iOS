import MEGADomain

public extension PhotoLibrary {
    /// Replace the item at each given flat index with its supplied node, preserving the tree
    /// structure — section shape and total count are unchanged, only leaves swap. Indices
    /// outside the tree are ignored. One traversal regardless of how many splices, so a window
    /// made of several placeholder runs is hydrated in a single O(total photos) rebuild.
    func replacingPhotos(at replacements: [Int: NodeEntity]) -> PhotoLibrary {
        guard !replacements.isEmpty else { return self }
        var flatIndex = 0

        let newYears = photoByYearList.map { year in
            PhotoByYear(categoryDate: year.categoryDate, contentList: year.contentList.map { month in
                PhotoByMonth(categoryDate: month.categoryDate, contentList: month.contentList.map { day in
                    PhotoByDay(categoryDate: day.categoryDate, contentList: day.contentList.map { node -> NodeEntity in
                        let position = flatIndex
                        flatIndex += 1
                        return replacements[position] ?? node
                    })
                })
            })
        }
        return PhotoLibrary(photoByYearList: newYears)
    }

    /// Convenience over `replacingPhotos(at:)` for one contiguous run starting at `startIndex`.
    func replacingPhotos(from startIndex: Int, with replacements: [NodeEntity]) -> PhotoLibrary {
        guard !replacements.isEmpty, startIndex >= 0 else { return self }
        let indexed = replacements.enumerated().map { (startIndex + $0.offset, $0.element) }
        return replacingPhotos(at: Dictionary(uniqueKeysWithValues: indexed))
    }
}
