import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct ManageTagsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var shouldDismiss = false
    @FocusState private var hasFocus

    @StateObject private var viewModel: ManageTagsViewModel

    init(viewModel: @autoclosure @escaping () -> ManageTagsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    public var body: some View {
        content
            .background(TokenColors.Background.page.swiftUI)
            .onChange(of: shouldDismiss) {
                if $0 { dismiss() }
            }
            .task {
                await viewModel.loadAllTags()
            }
            .onDisappear {
                viewModel.cancelSearchingIfNeeded()
            }
    }
    
    var content: some View {
        VStack {
            topView
            bottomView
        }
        .background(TokenColors.Background.page.swiftUI)
    }
    
    var topView: some View {
        VStack {
            navigationBar
            textField
                .padding(.horizontal, TokenSpacing._5)
                .padding(.bottom, TokenSpacing._4)
        }
        .background(TokenColors.Background.surface1.swiftUI)
    }
    
    var navigationBar: some View {
        ManageTagsViewNavigationBar(viewModel: viewModel.navigationBarViewModel, cancelButtonTapped: $shouldDismiss)
    }

    private var textField: some View {
        HStack(spacing: 1) {
            Text("#")
                .padding(.leading, TokenSpacing._3)
            TextField(
                Strings.Localizable.CloudDrive.NodeInfo.NodeTags.AddTags.title,
                text: $viewModel.tagName,
                prompt: textViewPlaceHolder
            )
            .focused($hasFocus)
            .textInputAutocapitalization(.never)
            .onSubmit {
                viewModel.addTag()
            }
            .onChange(of: viewModel.tagName) { updatedTagName in
                viewModel.onTagNameChanged(with: updatedTagName)
            }
            .padding(.vertical, TokenSpacing._3)
            if hasFocus, viewModel.tagName.isNotEmpty {
                Button {
                    viewModel.clearTextField()
                } label: {
                    Image(.searchBarCloseCircle)
                        .resizable()
                        .frame(width: 17, height: 17)
                        .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
                }
                .padding(.horizontal, TokenSpacing._5)
            }
        }
        .foregroundStyle(TokenColors.Text.primary.swiftUI)
        .background(TokenColors.Background.surface2.swiftUI)
        .cornerRadius(TokenRadius.medium)
        .onAppear { self.hasFocus = viewModel.hasTextFieldFocus }
        .onChange(of: hasFocus) { viewModel.hasTextFieldFocus = $0 }
        .onChange(of: viewModel.hasTextFieldFocus) { hasFocus = $0 }
    }
    
    private var textViewPlaceHolder: Text {
        if #available(iOS 17.0, *) {
            Text(Strings.Localizable.CloudDrive.NodeInfo.NodeTags.AddTags.inputPlaceHolder).foregroundStyle(TokenColors.Text.placeholder.swiftUI)
        } else {
            Text(Strings.Localizable.CloudDrive.NodeInfo.NodeTags.AddTags.inputPlaceHolder).foregroundColor(TokenColors.Text.placeholder.swiftUI)
        }
    }
    
    private var bottomView: some View {
        VStack {
            searchTagStatusView

            if viewModel.containsExistingTags {
                ExistingTagsOverviewView(viewModel: viewModel.existingTagsViewModel)
            } else {
                Spacer()
            }
        }
    }

    @ViewBuilder
    private var searchTagStatusView: some View {
        switch viewModel.tagNameState {
        case .empty where viewModel.containsExistingTags:
            EmptyView()
        case .empty:
            hintView
        case .invalid:
            errorView(Strings.Localizable.CloudDrive.NodeInfo.NodeTags.AddTags.invalidTagName)
        case .tooLong:
            errorView(Strings.Localizable.CloudDrive.NodeInfo.NodeTags.AddTags.tagNameTooLong)
        case .valid where viewModel.canAddNewTag:
            addTagView
        case .valid where !viewModel.containsExistingTags:
            ExistingTagsLoadingView()
        case .valid:
            EmptyView()
        }
    }

    private var addTagView: some View {
        Button {
            viewModel.addTag()
        } label: {
            HStack(spacing: TokenSpacing._3) {
                Image(systemName: "plus")
                    .foregroundStyle(TokenColors.Icon.primary.swiftUI)

                Text(Strings.Localizable.CloudDrive.NodeInfo.NodeTags.AddTags.buttonTitle(viewModel.tagName))
                    .font(.body)
                    .foregroundStyle(TokenColors.Button.primary.swiftUI)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, TokenSpacing._5)
        .padding(.top, TokenSpacing._5)
    }

    private var hintView: some View {
        Text(Strings.Localizable.CloudDrive.NodeInfo.NodeTags.AddTags.hint)
            .font(.footnote)
            .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            .padding(.horizontal, TokenSpacing._5)
    }

    private func errorView(_ errorString: String) -> some View {
        Text(errorString)
            .font(.footnote)
            .foregroundStyle(TokenColors.Text.error.swiftUI)
            .padding(.horizontal, TokenSpacing._5)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
