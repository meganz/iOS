import MEGADomain

struct FutureMeetingSection {
    let title: String
    let items: [FutureMeetingRoomViewModel]

    func filter(withSearchText searchText: String) -> FutureMeetingSection? {
        let filteredItems = items.filter { $0.contains(searchText: searchText) }
        return filteredItems.isEmpty ? nil : FutureMeetingSection(title: title, items: filteredItems)
    }
}
