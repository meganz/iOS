import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import Search
import SwiftUI

struct RecentActionBucketItemsView: View {
    struct Dependency {
        let nodes: [NodeEntity]
        let resultMapper: any RecentActionBucketItemResultMapping
        let selectionHandler: any NodeSelectionHandling
        let nodeActionHandler: any NodesActionHandling
    }
    
    @StateObject private var viewModel: RecentActionBucketItemsViewModel
    private let dependency: Dependency
    @EnvironmentObject var navigator: HomeNavigation

    init(dependency: Dependency) {
        self.dependency = dependency
        _viewModel = StateObject(
            wrappedValue: RecentActionBucketItemsViewModel(
                dependency: RecentActionBucketItemsViewModel.Dependency(
                    nodes: dependency.nodes,
                    resultMapper: dependency.resultMapper
                )
            )
        )
    }
    
    var body: some View {
        SearchResultsContainerView(viewModel: viewModel.searchResultsContainerViewModel)
            .navigationTitle("Bucket items")
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    leadingBarButton
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    trailingBarButton
                }
            }
            .environment(\.editMode, $viewModel.editMode)
            .onReceive(viewModel.$selection.compactMap { $0 }) { selection in
                dependency.selectionHandler.handle(selection: selection)
            }
            .onReceive(viewModel.$nodeAction.compactMap { $0 }) { action in
                dependency.nodeActionHandler.handle(action: action)
            }
    }

    @ViewBuilder
    private var leadingBarButton: some View {
        if viewModel.editMode.isEditing {
            Button {
                viewModel.toggleSelectAll()
            } label: {
                Label {
                    Text(Strings.Localizable.selectAll)
                } icon: {
                    MEGAAssets.Image.checkStack
                        .renderingMode(.template)
                        .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                        .padding(10)
                }
                .labelStyle(.iconOnly)
            }
        } else {
            Button {
                navigator.removeLast()
            } label: {
                Image(uiImage: MEGAAssets.UIImage.backArrow)
                    .renderingMode(.template)
                    .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                    .padding(10)
            }
        }
    }

    @ViewBuilder
    private var trailingBarButton: some View {
        if viewModel.editMode.isEditing {
            Button(Strings.Localizable.cancel) {
                viewModel.editMode = .inactive
            }
        }
    }
}
