import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct ManageTagsViewNavigationBar: View {
    @StateObject private var viewModel: ManageTagsViewNavigationBarViewModel
    @Binding var cancelButtonTapped: Bool

    init(viewModel: @autoclosure @escaping () -> ManageTagsViewNavigationBarViewModel, cancelButtonTapped: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: viewModel())
        _cancelButtonTapped = cancelButtonTapped
    }

    var body: some View {
        NavigationBarView(
            leading: { cancelButton },
            trailing: { doneButton },
            center: { title },
            backgroundColor: TokenColors.Background.surface1.swiftUI
        )
        .padding(.top, TokenSpacing._5)
        .onChange(of: viewModel.cancelButtonTapped) {
            cancelButtonTapped = $0
        }
    }

    private var cancelButton: some View {
        Button {
            viewModel.cancelButtonTapped = true
        } label: {
            Text(Strings.Localizable.cancel)
                .font(.body)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
        }
    }

    private var doneButton: some View {
        Button {
            // To be done in [SAO-1819]
        } label: {
            Text(Strings.Localizable.done)
                .font(.body)
                .foregroundStyle(viewModel.doneButtonDisabled ? TokenColors.Text.disabled.swiftUI : TokenColors.Text.primary.swiftUI)
        }
        .disabled(viewModel.doneButtonDisabled)
    }

    private var title: some View {
        Text(Strings.Localizable.CloudDrive.NodeInfo.NodeTags.AddTags.title)
            .font(.system(.headline).bold())
            .foregroundStyle(TokenColors.Text.primary.swiftUI)
    }
}
