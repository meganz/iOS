import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import Search
import SwiftUI

struct RecentActionBucketItemsView: View {
    struct Dependency {
        let bucket: RecentActionBucketEntity
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
                    bucket: dependency.bucket,
                    resultMapper: dependency.resultMapper
                )
            )
        )
    }
    
    var body: some View {
        SearchResultsContainerView(viewModel: viewModel.searchResultsContainerViewModel)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    RecentActionBucketNavigationTitleView(
                        title: viewModel.navigationTitle,
                        subtitle: viewModel.navigationSubtitle
                    )
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    leadingBarButton
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    trailingBarButton
                }
                
                if viewModel.editMode.isEditing {
                    ToolbarItemGroup(placement: .bottomBar) {
                        bottomBar
                    }
                }
            }
            .environment(\.editMode, $viewModel.editMode)
            .onReceive(viewModel.$selection.compactMap { $0 }) { selection in
                dependency.selectionHandler.handle(selection: selection)
            }
            .onReceive(viewModel.$nodeAction.compactMap { $0 }) { action in
                dependency.nodeActionHandler.handle(action: action)
            }
            .onChange(of: viewModel.editMode) { mode in
                navigator.tabBarHidden = mode.isEditing
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
    
    @ViewBuilder
    private var bottomBar: some View {
        Button {
            
        } label: {
            Label(title: { Text("Offline") }, icon: { MEGAAssets.Image.cloudDownload })
        }
        .labelStyle(.iconOnly)
        
        Spacer()
        
        Button {
            
        } label: {
            Label(title: { Text("Share") }, icon: { MEGAAssets.Image.link01 })
        }
        .labelStyle(.iconOnly)
        
        Spacer()
        
        Button {
            
        } label: {
            Label(title: { Text("Move") }, icon: { MEGAAssets.Image.moveMono })
        }
        .labelStyle(.iconOnly)
        
        Spacer()
        
        Button {
            
        } label: {
            Label(title: { Text("Remove") }, icon: { MEGAAssets.Image.trash })
        }
        .labelStyle(.iconOnly)
        
        Spacer()
        
        Button {
            
        } label: {
            Label(title: { Text("More") }, icon: { MEGAAssets.Image.moreHorizontal })
        }
        .labelStyle(.iconOnly)
    }
}
