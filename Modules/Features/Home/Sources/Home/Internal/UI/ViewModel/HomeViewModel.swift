import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var isSearching: Bool = false
    @Published var presentsSheet = false
    @Published var hidesFloatingActionsButton: Bool = false
    let widgets: [HomeWidgetType] = [.shortcuts, .accountDetails, .promotionalBanners, .recents]
}
