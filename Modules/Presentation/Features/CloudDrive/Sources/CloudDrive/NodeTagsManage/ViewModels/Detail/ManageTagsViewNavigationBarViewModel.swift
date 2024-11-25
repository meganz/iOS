import SwiftUI

@MainActor
final class ManageTagsViewNavigationBarViewModel: ObservableObject {
    @Binding var doneButtonDisabled: Bool
    @Published var cancelButtonTapped: Bool = false
    
    init(doneButtonDisabled: Binding<Bool>) {
        _doneButtonDisabled = doneButtonDisabled
    }
}
