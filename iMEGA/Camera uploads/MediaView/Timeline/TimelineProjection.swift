import ContentLibraries
import Foundation
import MEGADomain

/// A library, the sections describing it, and the lookups hydration needs over the pair.
///
/// Hydration plans against a projection rather than `dateSections` because the two disagree while a
/// reactive pass assembles a new snapshot: planning reads a layout, the fetch suspends, then the
/// splice resolves positions again. Passing the pair as one value keeps both ends on one layout.
///
/// Building one costs the buckets, never the nodes. `hydratedCoordinates` is carried in by the view
/// model rather than derived here, which would mean walking every slot.
struct TimelineProjection: Sendable {
    /// A slot's address. Hydration carries these rather than flat indices, which a bucket resizing
    /// elsewhere would invalidate.
    struct BucketCoordinate: Sendable, Equatable {
        let groupId: String
        let localOffset: Int
    }

    let library: PhotoLibrary
    let sections: [MediaDateSectionEntity]

    /// Prefix sums over `sections`, total appended, so a flat index bisects to its section.
    private let sectionBases: [Int]

    /// Each `groupId`'s position in `sections`, so a bucket's base is a dictionary hit.
    private let sectionIndexByGroupId: [String: Int]

    /// The library's day buckets in flat order, with prefix sums of their own. Slot lookups read
    /// these rather than the sections, which the eager path does not publish at all.
    private let days: [PhotoByDay]
    private let dayBases: [Int]

    /// Where each fetched node sits, keyed by handle: the splice's duplicate check and anchor
    /// lookup. Must describe `library` exactly, so the commit that produced both hands it over.
    let hydratedCoordinates: [HandleEntity: BucketCoordinate]

    /// Slots in the library, placeholders included.
    var itemCount: Int { dayBases[days.count] }

    init(
        library: PhotoLibrary,
        sections: [MediaDateSectionEntity],
        hydratedCoordinates: [HandleEntity: BucketCoordinate]
    ) {
        self.library = library
        self.sections = sections
        self.hydratedCoordinates = hydratedCoordinates

        var sectionBases = [Int]()
        sectionBases.reserveCapacity(sections.count + 1)
        var sectionIndexByGroupId = [String: Int](minimumCapacity: sections.count)
        var cumulative = 0
        for (index, section) in sections.enumerated() {
            sectionBases.append(cumulative)
            // First occurrence wins; the SDK does not repeat a `groupId` within one layout.
            if sectionIndexByGroupId[section.groupId] == nil {
                sectionIndexByGroupId[section.groupId] = index
            }
            cumulative += section.count
        }
        sectionBases.append(cumulative)
        self.sectionBases = sectionBases
        self.sectionIndexByGroupId = sectionIndexByGroupId

        let days = library.photosByDayList
        var dayBases = [Int]()
        dayBases.reserveCapacity(days.count + 1)
        var dayCumulative = 0
        for day in days {
            dayBases.append(dayCumulative)
            dayCumulative += day.contentList.count
        }
        dayBases.append(dayCumulative)
        self.days = days
        self.dayBases = dayBases
    }

    // MARK: - Slots

    /// The node at a flat index, or nil outside the tree.
    func node(at index: Int) -> NodeEntity? {
        guard let dayIndex = dayIndex(containing: index) else { return nil }
        return days[dayIndex].contentList[index - dayBases[dayIndex]]
    }

    /// The node at a flat index once fetched; nil for a placeholder or outside the tree.
    func hydratedNode(at index: Int) -> NodeEntity? {
        guard let node = node(at: index), !node.isTimelinePlaceholder else { return nil }
        return node
    }

    /// Whether the slot is still waiting to be fetched.
    func isPlaceholder(at index: Int) -> Bool {
        node(at: index)?.isTimelinePlaceholder == true
    }

    // MARK: - Buckets

    /// Where `groupId`'s bucket starts, or nil when a reshape removed it.
    func base(ofGroupId groupId: String) -> Int? {
        sectionIndexByGroupId[groupId].map { sectionBases[$0] }
    }

    func containsSection(groupId: String) -> Bool {
        sectionIndexByGroupId[groupId] != nil
    }

    /// The section a flat index falls in, and the index's offset within it.
    func sectionAnchor(
        forFlatIndex index: Int
    ) -> (section: MediaDateSectionEntity, localOffset: Int)? {
        guard let sectionIndex = sectionIndex(containing: index) else { return nil }
        return (sections[sectionIndex], index - sectionBases[sectionIndex])
    }

    /// The `groupId` of every section `range` overlaps — the buckets a hydration of it depends on.
    /// Bisected to the first, so a window at the bottom skips the sections above.
    func groupIds(spanning range: Range<Int>) -> [String] {
        guard let first = sectionIndex(containing: range.lowerBound) else { return [] }
        var groupIds: [String] = []
        for index in first..<sections.count {
            guard sectionBases[index] < range.upperBound else { break }
            guard sectionBases[index + 1] > range.lowerBound else { continue }
            groupIds.append(sections[index].groupId)
        }
        return groupIds
    }

    // MARK: - Handles

    /// Where the fetched node with this handle sits in *this* layout.
    func flatIndex(ofHandle handle: HandleEntity) -> Int? {
        hydratedCoordinates[handle].flatMap(flatIndex(of:))
    }

    /// Where an address lands in this layout, or nil once that bucket is gone.
    func flatIndex(of coordinate: BucketCoordinate) -> Int? {
        base(ofGroupId: coordinate.groupId).map { $0 + coordinate.localOffset }
    }

    // MARK: - Private

    /// The last bucket starting at or before `index`. Empty buckets share the next one's base and
    /// the bisection takes the highest match, so an index never lands on an empty one.
    private func dayIndex(containing index: Int) -> Int? {
        guard index >= 0, index < itemCount else { return nil }
        return Self.bucketIndex(containing: index, in: dayBases, count: days.count)
    }

    private func sectionIndex(containing index: Int) -> Int? {
        guard index >= 0, index < sectionBases[sections.count] else { return nil }
        return Self.bucketIndex(containing: index, in: sectionBases, count: sections.count)
    }

    private static func bucketIndex(containing index: Int, in bases: [Int], count: Int) -> Int {
        var low = 0
        var high = count - 1
        while low < high {
            let middle = (low + high + 1) / 2
            if bases[middle] <= index { low = middle } else { high = middle - 1 }
        }
        return low
    }
}
