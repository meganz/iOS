import Foundation
import MEGADomain

public protocol PhotoSection: PhotoChronologicalCategory where Content == NodeEntity {
    var title: String { get }

    var attributedTitle: AttributedString { get }
}

extension PhotoSection {
    public var coverPhoto: NodeEntity? {
        contentList.first?.coverPhoto
    }
}

public class PhotoDateSection: PhotoSection {
    public var id: String { title }
    public let photoByDayList: [PhotoByDay]
    public let categoryDate: Date
    public let title: String

    public let itemCount: Int

    /// The flat index each day bucket starts at, so an item can be located by bisecting the days
    /// instead of walking them. The masonry section holds the whole library's days, not a month's.
    private let dayStartIndices: [Int]

    init(photoByDayList: [PhotoByDay], categoryDate: Date, title: String = "") {
        self.photoByDayList = photoByDayList
        self.categoryDate = categoryDate
        self.title = title

        var starts = [Int]()
        starts.reserveCapacity(photoByDayList.count)
        var total = 0
        for day in photoByDayList {
            starts.append(total)
            total += day.contentList.count
        }
        dayStartIndices = starts
        itemCount = total
    }

    public var contentList: [NodeEntity] {
        photoByDayList.flatMap(\.contentList)
    }

    /// The section's items in flat order, without materialising them.
    var nodes: some Sequence<NodeEntity> {
        photoByDayList.lazy.flatMap(\.contentList)
    }

    public var attributedTitle: AttributedString {
        AttributedString()
    }

    /// The day bucket the cover photo sits in — not the section's own `categoryDate`, which is a
    /// month at month zoom. `PhotoByDay` does not forbid an empty bucket, so this is resolved
    /// through the item lookup rather than off `photoByDayList.first`: a leading empty day must
    /// not date the cover, or hide it.
    public var coverDayDate: Date? { item(at: 0)?.day.categoryDate }

    /// Overrides the `PhotoSection` default, which reaches the same node through `contentList` and
    /// would flatten the whole section to read one item.
    public var coverPhoto: NodeEntity? { item(at: 0)?.node }

    /// The item at `index` in the section's flat order, or `nil` when out of bounds.
    public func node(at index: Int) -> NodeEntity? {
        item(at: index)?.node
    }

    /// `categoryDate` of the day bucket holding the item at `index`.
    func dayCategoryDate(at index: Int) -> Date? {
        item(at: index)?.day.categoryDate
    }

    private func item(at index: Int) -> (node: NodeEntity, day: PhotoByDay)? {
        guard let dayIndex = dayIndex(containing: index) else { return nil }
        let day = photoByDayList[dayIndex]
        return (day.contentList[index - dayStartIndices[dayIndex]], day)
    }

    /// The day bucket holding flat item `index`: the last one starting at or before it. Empty
    /// buckets share the next one's start, and the bisection settles on the highest match, so an
    /// index is never resolved to a bucket that has no items.
    private func dayIndex(containing index: Int) -> Int? {
        guard index >= 0, index < itemCount else { return nil }
        var low = 0
        var high = dayStartIndices.count - 1
        while low < high {
            let middle = (low + high + 1) / 2
            if dayStartIndices[middle] <= index {
                low = middle
            } else {
                high = middle - 1
            }
        }
        return low
    }
}

extension PhotoDateSection {
    /// Overrides the `PhotoChronologicalCategory` default, which compares `contentList` and would
    /// flatten both sections to do it. The day buckets are what that list is built from, so
    /// comparing them is equivalent, and array equality shortcuts on buffer identity — the buckets
    /// a rebuild carried over unchanged cost nothing.
    public static func == (lhs: PhotoDateSection, rhs: PhotoDateSection) -> Bool {
        lhs.categoryDate == rhs.categoryDate && lhs.photoByDayList == rhs.photoByDayList
    }
}
