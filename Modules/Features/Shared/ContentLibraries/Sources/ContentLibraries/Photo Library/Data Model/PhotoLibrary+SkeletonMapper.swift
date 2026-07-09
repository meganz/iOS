import Foundation
import MEGADomain

extension PhotoLibrary {
    /// Builds a skeleton `PhotoLibrary` sized purely from date-bucket counts, before any
    /// real node has been fetched. Every slot is a placeholder `NodeEntity`, so the tree
    /// flows through the existing collection-view coordinator (which reads
    /// `contentList.count` and `photo(at:)`) unchanged.
    ///
    /// Expects day-granularity sections in display order (as returned by `dateSections`);
    /// the resulting tree preserves that order. Sections are UTC-canonical buckets, so
    /// month/year aggregation is done in GMT to keep the tree boundaries aligned with the
    /// SDK buckets.
    public static func skeleton(from sections: [MediaDateSectionEntity]) -> PhotoLibrary {
        let gmt = TimeZone(secondsFromGMT: 0)
        var nextHandleOffset: UInt64 = 0

        // Day level — one PhotoByDay per section, filled with `count` placeholder slots.
        let days: [PhotoByDay] = sections.compactMap { section in
            guard section.count > 0 else { return nil }
            let placeholders = (0..<section.count).map { _ -> NodeEntity in
                defer { nextHandleOffset += 1 }
                return NodeEntity.timelinePlaceholder(offset: nextHandleOffset, date: section.startDate)
            }
            return PhotoByDay(categoryDate: section.startDate, contentList: placeholders)
        }

        // `removeDay`/`removeMonth` are `Date?` only because `Calendar.date(from:)` is
        // failable; for year/month components taken from a real date it never returns nil.
        // Fall back to the day date itself so a slot can never be silently dropped even if
        // that ever changed — the skeleton's total item count must always equal the sum of
        // the section counts (fast-scroll track length, section headers and empty state all
        // depend on it). A stray fallback would at worst mis-group a month, never lose a slot.
        let months = days.grouped(by: { $0.categoryDate.removeDay(timeZone: gmt) ?? $0.categoryDate })
            .map { PhotoByMonth(categoryDate: $0.key, contentList: $0.value) }

        let years = months.grouped(by: { $0.categoryDate.removeMonth(timeZone: gmt) ?? $0.categoryDate })
            .map { PhotoByYear(categoryDate: $0.key, contentList: $0.value) }

        return PhotoLibrary(photoByYearList: years)
    }
}

private extension Array {
    /// Groups elements by a key, preserving the order in which keys first appear.
    /// The key is non-optional by design: this mapper must never drop an element, or
    /// the skeleton's item count would silently diverge from the section counts.
    func grouped<Key: Hashable>(by key: (Element) -> Key) -> [(key: Key, value: [Element])] {
        var order: [Key] = []
        var buckets: [Key: [Element]] = [:]
        for element in self {
            let k = key(element)
            if buckets[k] == nil { order.append(k) }
            buckets[k, default: []].append(element)
        }
        return order.map { ($0, buckets[$0] ?? []) }
    }
}
