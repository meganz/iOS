import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

public struct AddToCollectionView: View {
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: AddToCollectionViewModel
    
    public init(viewModel: @autoclosure @escaping () -> AddToCollectionViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }
    
    public var body: some View {
        NavigationStackView {
            content
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Text(Strings.Localizable.cancel)
                                .font(.body)
                                .foregroundColor(TokenColors.Text.secondary.swiftUI)
                        }
                    }
                    ToolbarItemGroup(placement: .bottomBar) {
                        Spacer()
                        
                        Button {
                            viewModel.addToCollectionTapped()
                            dismiss()
                        } label: {
                            Text(Strings.Localizable.Photos.AddTo.Button.Title.add)
                                .font(.body)
                                .foregroundColor(
                                    viewModel.isAddButtonDisabled ?
                                    TokenColors.Text.disabled.swiftUI :
                                        TokenColors.Text.secondary.swiftUI)
                        }
                        .disabled(viewModel.isAddButtonDisabled)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle(Strings.Localizable.Set.addTo)
        }
    }
    
    private var content: some View {
        AddToAlbumsView(viewModel: viewModel.addToAlbumsViewModel)
    }
}
