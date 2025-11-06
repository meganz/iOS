import MEGAAssets
import MEGADesignToken
import MEGADomain
import SwiftUI

@MainActor
public protocol NodeUploadActionSheetViewModelProtocol {
    var uploadActions: [NodeUploadAction] { get }

    // Due to the mixing of SwiftUI and UIKit in CD view architecture,
    // Once an action is selected from NodeUploadActionSheetView, we'll need to wait until the
    // sheet is completely dismissed in order to present the upload view/VCs on the hosting view controller
    // Therefore we need `saveSelectedAction` to save the selected action first, then use `performSelectedActionAfterDismissal`
    // to actually invoke the action.
    func saveSelectedAction(_ action: NodeUploadAction)
    func performSelectedActionAfterDismissal()
}

public struct NodeUploadActionSheetView: View {
    private let viewModel: any NodeUploadActionSheetViewModelProtocol
    // Binding variable to dismiss the sheet upon action selection.
    @Binding var isPresented: Bool

    public init(
        viewModel: some NodeUploadActionSheetViewModelProtocol,
        isPresented: Binding<Bool>
    ) {
        self.viewModel = viewModel
        self._isPresented = isPresented
    }
    public var body: some View {
        LazyVStack(spacing: .zero) {
            ForEach(viewModel.uploadActions) { action in
                UploadActionItemView(
                    image: action.image,
                    title: action.title,
                    actionHandler: {
                        isPresented = false
                        viewModel.saveSelectedAction(action)
                    })
            }
        }
        .onDisappear {
            viewModel.performSelectedActionAfterDismissal()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

private struct UploadActionItemView: View {
    private enum Constants {
        static let imageSize: CGFloat = 24
        static let itemHeight: CGFloat = 58

    }
    let image: Image
    let title: String

    let actionHandler: @MainActor () -> Void

    var body: some View {
        Button {
            actionHandler()
        } label: {
            HStack(spacing: TokenSpacing._4) {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Constants.imageSize, height: Constants.imageSize)
                    .foregroundStyle(TokenColors.Icon.primary.swiftUI)

                Text(title)
                    .font(.body)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                Spacer()
            }
        }
        .padding(.leading, TokenSpacing._6)
        .frame(height: Constants.itemHeight)
    }
}
