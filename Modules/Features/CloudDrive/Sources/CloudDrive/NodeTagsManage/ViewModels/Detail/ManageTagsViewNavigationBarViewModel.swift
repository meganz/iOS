import SwiftUI

@MainActor
final class ManageTagsViewNavigationBarViewModel: ObservableObject {
    @Published var doneButtonDisabled: Bool = true
    @Published var cancelButtonTapped: Bool = false
    @Published var doneButtonTapped: Bool = false
    let isLiquidGlassEnabled: Bool
    
    init(isLiquidGlassEnabled: Bool = false) {
        self.isLiquidGlassEnabled = isLiquidGlassEnabled
    }
}
