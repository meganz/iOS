import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var presentsSheet = false
    let widgets = HomeWidgetType.allCases

    init() {}
}
