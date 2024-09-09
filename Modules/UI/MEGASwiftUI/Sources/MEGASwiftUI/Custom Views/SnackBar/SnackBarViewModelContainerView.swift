import MEGADesignToken
import SwiftUI

struct SnackBarViewModelContainerView: View {
    @StateObject private var viewModel: SnackBarViewModel
    
    init(
        viewModel: @autoclosure @escaping () -> SnackBarViewModel
    ) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }
    
    var body: some View {
        SnackBarItemView(snackBar: viewModel.snackBar)
    }
}

// MARK: - Preview

#Preview {
    
    VStack {
        SnackBarViewModelContainerView(
            viewModel: SnackBarViewModel(
                snackBar: SnackBar(
                    message: "Your hand is raised",
                    layout: .crisscross,
                    action: .init(
                        title: "Lower hand",
                        handler: {}
                    ),
                    colors: .default
                ),
                willDismiss: nil
            )
        )
        SnackBarViewModelContainerView(
            viewModel: SnackBarViewModel(
                snackBar: SnackBar(
                    message: "Your hand is raised",
                    layout: .horizontal,
                    action: .init(
                        title: "Lower hand",
                        handler: {}
                    ),
                    colors: .raiseHand
                ),
                willDismiss: nil
            )
        )
        SnackBarViewModelContainerView(
            viewModel: SnackBarViewModel(
                snackBar: SnackBar(
                    message: "Message",
                    layout: .crisscross,
                    action: nil,
                    colors: .default
                ),
                willDismiss: nil
            )
        )
        SnackBarViewModelContainerView(
            viewModel: SnackBarViewModel(
                snackBar: SnackBar(
                    message: "Message",
                    layout: .horizontal,
                    action: nil,
                    colors: .default
                ),
                willDismiss: nil
            )
        )
    }
}
