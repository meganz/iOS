import MEGASwiftUI
import SwiftUI

struct HiddenFilesOnboardingButtonView: View {
    private let viewModel: any HiddenFilesOnboardingPrimaryButtonViewModelProtocol
    
    init(viewModel: some HiddenFilesOnboardingPrimaryButtonViewModelProtocol) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        PrimaryActionButtonView(title: viewModel.buttonTitle) {
            Task { @MainActor in
                await viewModel.buttonAction()
            }
        }
    }
}
