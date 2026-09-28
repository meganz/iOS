import Foundation
import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import Search
import SwiftUI

public struct ViewedLinksView: View {
    public struct Dependency {
        let openLink: @MainActor (URL) -> Void
        let showPostDismissalSnackBar: @MainActor (String) -> Void

        public init(
            openLink: @escaping @MainActor (URL) -> Void,
            showSnackBar: @escaping @MainActor (String) -> Void
        ) {
            self.openLink = openLink
            self.showPostDismissalSnackBar = showSnackBar
        }
    }

    @StateObject private var viewModel: ViewedLinksViewModel
    @Binding private var tabBarHidden: Bool
    @Environment(\.dismiss) private var dismiss
    private let showPostDismissalSnackBar: @MainActor (String) -> Void

    public init(
        dependency: Dependency,
        tabBarHidden: Binding<Bool>
    ) {
        _viewModel = StateObject(
            wrappedValue: ViewedLinksViewModel(
                openLink: dependency.openLink
            )
        )
        _tabBarHidden = tabBarHidden
        showPostDismissalSnackBar = dependency.showPostDismissalSnackBar
    }

    public var body: some View {
        SearchResultsContainerView(viewModel: viewModel.searchResultsContainerViewModel)
            .background(TokenColors.Background.page.swiftUI)
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    leadingBarButton
                }
                ToolbarItem(placement: .topBarTrailing) {
                    trailingBarButton
                }
            }
            .alert(
                viewModel.clearSelectedLinksTitle,
                isPresented: $viewModel.isPresentingClearSelectedConfirmation,
                actions: {
                    Button(Strings.Localizable.dismiss, action: {})
                    Button(Strings.Localizable.clear) {
                        Task {
                            if await viewModel.clearSelectedLinks() {
                                dismiss()
                            }
                        }
                    }
                }
            )
            .alert(
                Strings.Localizable.ViewedLinks.Clear.Action.title,
                isPresented: $viewModel.isPresentingClearAllConfirmation,
                actions: {
                    Button(Strings.Localizable.dismiss, action: {})
                    Button(Strings.Localizable.clear) {
                        Task {
                            if await viewModel.clearAllLinks() {
                                dismiss()
                            }
                        }
                    }
                },
                message: {
                    Text(Strings.Localizable.ViewedLinks.Clear.Confirmation.message)
                }
            )
            .miniPlayerAware()
            .environment(\.editMode, $viewModel.editMode)
            .onAppear {
                tabBarHidden = true
            }
            .onDisappear {
                tabBarHidden = false
                guard let message = viewModel.clearedSnackBarMessage else { return }
                showPostDismissalSnackBar(message)
            }
    }

    @ViewBuilder
    private var leadingBarButton: some View {
        if viewModel.editMode.isEditing {
            clearButtonView
        } else {
            BackButton()
        }
    }

    private var clearButtonView: some View {
        Button {
            viewModel.requestClearSelectedLinks()
        } label: {
            Label {
                Text(Strings.Localizable.clear)
            } icon: {
                MEGAAssets.Image.monoEraserMediumThinOutline
                    .renderingMode(.template)
                    .foregroundStyle(TokenColors.Icon.primary.swiftUI)
            }
            .labelStyle(.iconOnly)
        }
        .disabled(viewModel.selectedIds.isEmpty)
    }

    @ViewBuilder
    private var trailingBarButton: some View {
        if viewModel.editMode.isEditing {
            Button(Strings.Localizable.cancel) {
                viewModel.exitEditMode()
            }
        } else {
            Menu {
                Button(Strings.Localizable.ViewedLinks.Clear.Action.title) {
                    viewModel.requestClearAllLinks()
                }
            } label: {
                MEGAAssets.Image.monoMoreHorizontalMediumThinOutline
                    .renderingMode(.template)
                    .foregroundStyle(TokenColors.Icon.primary.swiftUI)
            }
        }
    }
}
