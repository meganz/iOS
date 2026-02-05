import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var hidesFAB = false
    let widgets = HomeWidgetType.allCases

    init() {}
}
