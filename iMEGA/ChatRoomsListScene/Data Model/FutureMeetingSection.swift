import MEGADomain

@MainActor
struct FutureMeetingSection {
    let title: String
    let date: Date
    private(set) var items: [FutureMeetingRoomViewModel]

    func filter(withSearchText searchText: String) -> FutureMeetingSection? {
        let filteredItems = items.filter { $0.contains(searchText: searchText) }
        return filteredItems.isEmpty ? nil : FutureMeetingSection(title: title, date: date, items: filteredItems)
    }

    mutating func insert(_ item: FutureMeetingRoomViewModel) {
        if let index = items.firstIndex(where: { $0 > item }) {
            items.insert(item, at: index)
        } else {
            items.append(item)
        }
    }
}

extension FutureMeetingSection: Comparable {
    nonisolated static func == (lhs: FutureMeetingSection, rhs: FutureMeetingSection) -> Bool {
        lhs.date == rhs.date
    }
    
    nonisolated static func < (lhs: FutureMeetingSection, rhs: FutureMeetingSection) -> Bool {
        lhs.date < rhs.date
    }
}
