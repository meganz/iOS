import MEGADesignToken
import MEGAPresentation
import MEGAUIComponent
import SwiftUI

struct SecondarySceneView: View {
    @StateObject var viewModel: SecondarySceneViewModel

    var body: some View {
        ZStack {
            snackbarContainer
            appLoadingContainer
        }
    }

    @ViewBuilder private var snackbarContainer: some View {
        VStack(spacing: .zero) {
            Spacer()
            if let snackbar = viewModel.snackbarEntity {
                MEGASnackbar(snackBarEntity: snackbar)
                    .padding(TokenSpacing._5)
                    .padding(.bottom, viewModel.snackbarBottomPadding)
            }
        }
    }

    @ViewBuilder private var appLoadingContainer: some View {
        if let appLoadingEntity = viewModel.appLoading {
            LoadingScreenView()
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .center
                )
                .background(
                    .ultraThinMaterial.opacity(appLoadingEntity.blur ? 0.7 : 0)
                )
                .allowsHitTesting(!appLoadingEntity.allowUserInteraction)
        }
    }
}

struct SecondarySceneView_Previews: PreviewProvider {
    static var previews: some View {
        SecondarySceneView(viewModel: previewViewModel())
    }

    static func previewViewModel() -> SecondarySceneViewModel {
        let viewModel = SecondarySceneViewModel()
        var ticker = 0

        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            ticker += 1
            if ticker.isMultiple(of: 2) {
                viewModel.snackbarEntity = nil
            } else {
                viewModel.snackbarEntity = .init(text: "Preview")
            }
        }

        return viewModel
    }
}

extension MEGASnackbar {
    init(snackBarEntity: SnackbarEntity) {
        self.init(
            text: snackBarEntity.text,
            showtime: snackBarEntity.showtime,
            actionLabel: snackBarEntity.actionLabel,
            action: snackBarEntity.action,
            onDismiss: snackBarEntity.onDismiss
        )
    }
}
