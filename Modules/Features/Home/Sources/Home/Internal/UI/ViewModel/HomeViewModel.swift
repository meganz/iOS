import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var presentsSheet = false
    @Published var hidesFloatingActionsButton: Bool = false
    @Published var selectedFloatingButtonAction: HomeAddMenuAction?
    let widgets = HomeWidgetType.allCases
}
