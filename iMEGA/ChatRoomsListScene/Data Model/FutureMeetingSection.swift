import MEGADomain

struct FutureMeetingSection {
    let title: String
    let date: Date
    let items: [FutureMeetingRoomViewModel]

    var allChatIds: [ChatIdEntity] {
        items.map(\.scheduledMeeting.chatId)
    }

    func filter(withSearchText searchText: String) -> FutureMeetingSection? {
        let filteredItems = items.filter { $0.contains(searchText: searchText) }
        return filteredItems.isEmpty ? nil : FutureMeetingSection(title: title, date: date, items: filteredItems)
    }
    
    func contains(itemsWithChatId chatId: ChatIdEntity) -> Bool {
        items.filter { $0.scheduledMeeting.chatId == chatId }.isNotEmpty
    }    
}
