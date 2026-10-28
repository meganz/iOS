import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import Search
import SwiftUI
import Transfer

public struct ContinueWhereYouLeftOffView: View {
    public struct Dependency {
        let leftOffItemsUseCase: any LeftOffItemsUseCaseProtocol
        let thumbnailUseCase: any ThumbnailUseCaseProtocol
        let selectionHandler: any NodeSelectionHandling
        let makeOfflineNodeTapDispatcher: () -> OfflineAwareNodeTapDispatcher
        let transferIndicatorToolbarFactory: TransferIndicatorToolbarFactory

        public init(
            leftOffItemsUseCase: some LeftOffItemsUseCaseProtocol,
            thumbnailUseCase: some ThumbnailUseCaseProtocol,
            selectionHandler: some NodeSelectionHandling,
            makeOfflineNodeTapDispatcher: @escaping () -> OfflineAwareNodeTapDispatcher,
            transferIndicatorToolbarFactory: TransferIndicatorToolbarFactory
        ) {
            self.leftOffItemsUseCase = leftOffItemsUseCase
            self.thumbnailUseCase = thumbnailUseCase
            self.selectionHandler = selectionHandler
            self.makeOfflineNodeTapDispatcher = makeOfflineNodeTapDispatcher
            self.transferIndicatorToolbarFactory = transferIndicatorToolbarFactory
        }
    }

    @StateObject private var viewModel: LeftOffItemsViewModel
    @StateObject private var offlineNodeTapGate: LeftOffItemsOfflineNodeTapGate
    @Binding private var tabBarHidden: Bool
    @Environment(\.dismiss) private var dismiss
    private let transferIndicatorToolbarFactory: TransferIndicatorToolbarFactory

    public init(
        dependency: Dependency,
        tabBarHidden: Binding<Bool>
    ) {
        let selectionHandler = dependency.selectionHandler
        let gate = LeftOffItemsOfflineNodeTapGate(dispatcher: dependency.makeOfflineNodeTapDispatcher())
        _offlineNodeTapGate = StateObject(wrappedValue: gate)
        _viewModel = StateObject(
            wrappedValue: LeftOffItemsViewModel(
                leftOffItemsUseCase: dependency.leftOffItemsUseCase,
                thumbnailUseCase: dependency.thumbnailUseCase,
                openNode: {
                    gate.handler(wrapping: selectionHandler)
                        .handle(selection: NodeSelection(handle: $0, siblings: []))
                }
            )
        )
        _tabBarHidden = tabBarHidden
        transferIndicatorToolbarFactory = dependency.transferIndicatorToolbarFactory
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
                transferIndicatorToolbarFactory.toolbarContent(trailingItemCount: 1)
                ToolbarItem(placement: .topBarTrailing) {
                    trailingBarButton
                }
            }
            .alert(
                viewModel.clearSelectedItemsTitle,
                isPresented: $viewModel.isPresentingClearSelectedConfirmation,
                actions: {
                    Button(Strings.Localizable.dismiss, action: {})
                    Button(Strings.Localizable.clear) {
                        Task {
                            await viewModel.clearSelectedItems()
                        }
                    }
                }
            )
            .alert(
                Strings.Localizable.ContinueWhereYouLeftOff.Clear.Confirmation.title,
                isPresented: $viewModel.isPresentingClearAllConfirmation,
                actions: {
                    Button(Strings.Localizable.dismiss, action: {})
                    Button(Strings.Localizable.clear) {
                        Task {
                            if await viewModel.clearAllItems() {
                                dismiss()
                            }
                        }
                    }
                },
                message: {
                    Text(Strings.Localizable.ContinueWhereYouLeftOff.Clear.Confirmation.message)
                }
            )
            .snackBar($offlineNodeTapGate.snackBar)
            .miniPlayerAware()
            .environment(\.editMode, $viewModel.editMode)
            .onAppear {
                tabBarHidden = true
                viewModel.onAppear()
            }
            .onDisappear {
                tabBarHidden = false
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
            viewModel.requestClearSelectedItems()
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
                Button(Strings.Localizable.ContinueWhereYouLeftOff.Clear.Confirmation.title) {
                    viewModel.requestClearAllItems()
                }
            } label: {
                MEGAAssets.Image.monoMoreHorizontalMediumThinOutline
                    .renderingMode(.template)
                    .foregroundStyle(TokenColors.Icon.primary.swiftUI)
            }
        }
    }
}
