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

    /// Overlay per-node metadata from `other` onto the receiver, matched by handle and keeping the
    /// receiver's positions. For each real (non-placeholder) node here, if `other` holds a real node
    /// with the same handle and `preferOther(mine, other)` says so, swap in `other`'s node. Used to
    /// reconcile a shape result built from a stale snapshot with a metadata patch that landed
    /// concurrently, so the patch isn't reverted. Placeholders never match (synthetic handles), so a
    /// node freshly hydrated by this pass — still a placeholder in `other` — is never overridden. The
    /// `preferOther` predicate owns the field policy (see the caller). One `replacingPhotos(at:)`
    /// rebuild; a no-op when nothing is preferred.
    func mergingMetadata(
        from other: PhotoLibrary,
        preferringOtherWhen preferOther: (_ mine: NodeEntity, _ other: NodeEntity) -> Bool
    ) -> PhotoLibrary {
        let otherByHandle = Dictionary(
            other.allPhotos.lazy.filter { !$0.isTimelinePlaceholder }.map { ($0.handle, $0) },
            uniquingKeysWith: { first, _ in first })
        guard !otherByHandle.isEmpty else { return self }

        var replacements: [Int: NodeEntity] = [:]
        for (index, node) in allPhotos.enumerated() where !node.isTimelinePlaceholder {
            guard let other = otherByHandle[node.handle], preferOther(node, other) else { continue }
            replacements[index] = other
        }
        return replacingPhotos(at: replacements)
    }
}
