import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import Search
import SwiftUI

struct RecentActionBucketsListView: View {
    struct Dependency {
        let userNameProvider: any UserNameProviderProtocol
        let recentActionBucketItemResultMapper: any RecentActionBucketItemResultMapping
        let selectionHandler: any NodeSelectionHandling
        let nodeActionHandler: any NodesActionHandling
    }

    enum Route: Hashable {
        case bucketItems([NodeEntity])
    }
    
    private let dependency: Dependency
    @StateObject private var viewModel = RecentActionBucketsListViewModel()
    @EnvironmentObject var navigator: HomeNavigation
    
    init(dependency: Dependency) {
        self.dependency = dependency
    }
    
    var body: some View {
        content
            .navigationTitle(Strings.Localizable.recents)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    moreOptionsButton
                }
            }
            .background(TokenColors.Background.page.swiftUI)
            .navigationDestination(for: Route.self) { route in
                navigationDestination(for: route)
            }
            .alert(
                Strings.Localizable.Home.Recent.Menu.Action.clearRecentActivity,
                isPresented: $viewModel.isConfirmingClearRecentActivity,
                actions: {
                    Button(Strings.Localizable.dismiss, action: {})
                    Button(Strings.Localizable.clear) {
                        Task {
                            await viewModel.clearRecentActivity()
                            navigator.removeLast()
                        }
                    }
                },
                message: {
                    Text(Strings.Localizable.Home.Recent.ClearRecentActivity.Alert.message)
                }
            )
            .onDisappear {
                if let snackBar = viewModel.recentActivityHiddenSnackBar {
                    navigator.showSnackBar(snackBar)
                }
                
                if let snackBar = viewModel.recentActivityClearedSnackBar {
                    navigator.showSnackBar(snackBar)
                }
            }
    }
    
    @ViewBuilder
    private var content: some View {
        switch viewModel.viewState {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(TokenColors.Background.page.swiftUI)
                .onFirstLoad {
                    await viewModel.loadRecentActionBuckets()
                }
        case let .results(sections):
            if #available(iOS 17.0, *) {
                bucketsContent(sections: sections)
                    .listSectionSpacing(0)
            } else {
                bucketsContent(sections: sections)
            }
        }
    }
    
    private var moreOptionsButton: some View {
        Menu {
            Button {
                viewModel.hideRecentActivity()
                navigator.removeLast()
            } label: {
                Label {
                    Text(Strings.Localizable.Settings.UserInterface.hideRecentActivity)
                } icon: {
                    MEGAAssets.Image.eyeOff
                        .renderingMode(.template)
                        .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
                }
            }
            
            Button {
                viewModel.confirmClearRecentActivity()
            } label: {
                Label {
                    Text(Strings.Localizable.Home.Recent.Menu.Action.clearRecentActivity)
                } icon: {
                    MEGAAssets.Image.clearChatHistory
                        .renderingMode(.template)
                        .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
                }
            }
        } label: {
            Label {
                Text(Strings.Localizable.more)
            } icon: {
                MEGAAssets.Image.moreHorizontal
                    .renderingMode(.template)
                    .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
            }
            .labelStyle(.iconOnly)
        }
    }
    
    private func bucketsContent(sections: [RecentActionBucketSection]) -> some View {
        List {
            ForEach(sections) { section in
                Section {
                    ForEach(section.buckets) { bucket in
                        RecentActionBucketContainerView(
                            dependency: RecentActionBucketContainerView.Dependency(
                                bucket: bucket,
                                userNameProvider: dependency.userNameProvider,
                                nodeActionHandler: { node in
                                    print(node.name)
                                },
                                bucketSelectionHandler: { bucket in
                                    switch bucket.type {
                                    case let .mixedFiles(nodes):
                                        navigator.append(Route.bucketItems(nodes))
                                    default:
                                        break
                                    }
                                }
                            )
                        )
                        .background(TokenColors.Background.page.swiftUI)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                    }
                } header: {
                    Text(section.title)
                        .font(.footnote)
                        .fontWeight(.regular)
                        .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                        .padding(.horizontal, TokenSpacing._5)
                        .padding(.vertical, TokenSpacing._3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(TokenColors.Background.page.swiftUI)
                }
                .listRowInsets(EdgeInsets())
            }
        }
        .listStyle(.plain)
    }

    @ViewBuilder
    private func navigationDestination(for route: Route) -> some View {
        switch route {
        case let .bucketItems(nodes):
            RecentActionBucketItemsView(
                dependency: RecentActionBucketItemsView.Dependency(
                    nodes: nodes,
                    resultMapper: dependency.recentActionBucketItemResultMapper,
                    selectionHandler: dependency.selectionHandler,
                    nodeActionHandler: dependency.nodeActionHandler
                )
            )
        }
    }
}
