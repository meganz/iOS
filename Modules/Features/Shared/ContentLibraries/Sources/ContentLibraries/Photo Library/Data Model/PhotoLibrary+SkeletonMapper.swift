import Foundation
import MEGADomain

extension PhotoLibrary {
    /// Builds a skeleton `PhotoLibrary` sized purely from date-bucket counts, before any
    /// real node has been fetched. Every slot is a placeholder `NodeEntity`, so the tree
    /// flows through the existing collection-view coordinator (which reads
    /// `contentList.count` and `photo(at:)`) unchanged.
    ///
    /// Expects day-granularity sections in display order (as returned by `dateSections`);
    /// the resulting tree preserves that order.
    ///
    /// Uses the SDK's local-calendar `groupId` for both headers and month/year grouping. Do not
    /// re-derive these from `startDate`: the SDK uses a fixed UTC offset and can cross a DST boundary.
    public static func skeleton(from sections: [MediaDateSectionEntity]) -> PhotoLibrary {
        var nextHandleOffset: UInt64 = 0

        // SDK groupIds are Gregorian; retain the user's time zone for local midnight.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current

        // Day level — one entry per non-empty section, filled with `count` placeholder slots.
        let days: [SkeletonDay] = sections.compactMap { section in
            guard section.count > 0 else { return nil }
            let placeholders = (0..<section.count).map { _ -> NodeEntity in
                defer { nextHandleOffset += 1 }
                return NodeEntity.timelinePlaceholder(offset: nextHandleOffset, date: section.startDate)
            }
            // Keep slots even if an unexpected groupId cannot be parsed.
            let dates = section.groupId.mediaSectionDates(using: calendar)
            return SkeletonDay(
                groupId: section.groupId,
                monthDate: dates?.month ?? section.startDate,
                yearDate: dates?.year ?? section.startDate,
                day: PhotoByDay(categoryDate: dates?.day ?? section.startDate, contentList: placeholders))
        }

        let years = days.grouped(by: { String($0.groupId.prefix(4)) }).map { yearGroup -> PhotoByYear in
            let months = yearGroup.value.grouped(by: { String($0.groupId.prefix(7)) }).map { monthGroup in
                PhotoByMonth(categoryDate: monthGroup.value[0].monthDate, contentList: monthGroup.value.map(\.day))
            }
            return PhotoByYear(categoryDate: yearGroup.value[0].yearDate, contentList: months)
        }

        return PhotoLibrary(photoByYearList: years)
    }
}

/// A skeleton day with its SDK bucket id and header dates.
private struct SkeletonDay {
    let groupId: String
    let monthDate: Date
    let yearDate: Date
    let day: PhotoByDay
}

private extension String {
    /// Parses a day-level Gregorian `groupId` into local day, month and year dates.
    func mediaSectionDates(using calendar: Calendar) -> (day: Date, month: Date, year: Date)? {
        let parts = split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        guard
            let day = calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2])),
            let month = calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: 1)),
            let year = calendar.date(from: DateComponents(year: parts[0], month: 1, day: 1))
        else { return nil }
        return (day, month, year)
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
