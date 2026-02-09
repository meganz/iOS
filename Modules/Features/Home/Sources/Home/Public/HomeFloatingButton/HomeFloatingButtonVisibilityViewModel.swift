import Combine
import SwiftUI

@MainActor
public final class HomeFloatingButtonVisibilityViewModel: ObservableObject {
    @Published var hidesFloatingActionsButton: Bool = false
    public init() {}
}
