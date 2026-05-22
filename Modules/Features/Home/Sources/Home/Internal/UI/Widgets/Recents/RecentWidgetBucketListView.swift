import ContentLibraries
import MEGAAppPresentation
import MEGADesignToken
import MEGADomain
import MEGAL10n
import Search
import SwiftUI
import Transfer

struct RecentWidgetBucketListView: View {
    struct Dependency {
        let bucketGroups: [DailyRecentActionBucketGroup]
        let userNameProvider: any UserNameProviderProtocol
        let recentActionBucketItemResultMapper: any RecentActionBucketItemResultMapping
        let downloadedNodesListener: any DownloadedNodesListening
        let selectionHandler: any NodeSelectionHandling
        let nodeActionHandler: any NodesActionHandling
        let moreActionsPresenter: any MoreNodeActionsPresenting
        let photoLibraryContentViewRouter: any PhotoLibraryContentViewRouting
        let transferIndicatorToolbarFactory: TransferIndicatorToolbarFactory
        let isHomeRevampPhaseTwoEnabled: Bool
    }

    enum Route: Hashable {
        case viewAllBuckets
        case bucketItems(RecentActionBucketEntity)
        case multipleMedia(String, RecentActionBucketEntity)
    }
    
    private let dependency: Dependency
    private let sections: [RecentActionBucketSection]
    private let recentActionBucketSectionMapper = RecentActionBucketSectionMapper()
    private let viewModel: RecentWidgetBucketListViewModel

    @EnvironmentObject var navigator: HomeNavigation

    init(
        dependency: Dependency,
        viewModel: RecentWidgetBucketListViewModel = RecentWidgetBucketListViewModel()
    ) {
        self.dependency = dependency
        self.viewModel = viewModel
        self.sections = recentActionBucketSectionMapper.map(
            bucketGroups: dependency.bucketGroups
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            bucketsContent
            if !dependency.isHomeRevampPhaseTwoEnabled {
                viewAllBucketsButton
            }
        }
        .navigationDestination(for: Route.self) { route in
            navigationDestination(for: route)
        }
    }

    private var viewAllBucketsButton: some View {
        Button {
            viewModel.trackViewAllTapped()
            navigator.append(Route.viewAllBuckets)
        } label: {
            Text(Strings.Localizable.Home.Recent.Widget.viewAll)
                .font(.callout)
                .fontWeight(.semibold)
                .underline()
                .foregroundStyle(TokenColors.Button.primary.swiftUI)
        }
        .padding(TokenSpacing._5)
    }
    
    private var bucketsContent: some View {
        ForEach(sections) { section in
            Section {
                ForEach(section.buckets) { bucket in
                    RecentActionBucketContainerView(
                        dependency: RecentActionBucketContainerView.Dependency(
                            bucket: bucket,
                            userNameProvider: dependency.userNameProvider,
                            nodeActionHandler: dependency.nodeActionHandler,
                            bucketSelectionHandler: { bucket in
                                switch bucket.type {
                                case .mixedFiles:
                                    navigator.append(Route.bucketItems(bucket))
                                case .multipleMedia:
                                    navigator.append(Route.multipleMedia(section.title, bucket))
                                case let .singleFile(node), let .singleMedia(node):
                                    dependency.selectionHandler.handle(selection: NodeSelection(handle: node.handle, siblings: []))
                                }
                            }
                        )
                    )
                }
            } header: {
                Text(section.title)
                    .font(.footnote)
                    .fontWeight(.regular)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                    .padding(.horizontal, TokenSpacing._5)
                    .padding(.vertical, TokenSpacing._3)
            }
        }
    }
    
    @ViewBuilder
    private func navigationDestination(for route: Route) -> some View {
        switch route {
        case .viewAllBuckets:
            RecentActionBucketsListView(
                dependency: RecentActionBucketsListView.Dependency(
                    userNameProvider: dependency.userNameProvider,
                    recentActionBucketItemResultMapper: dependency.recentActionBucketItemResultMapper,
                    downloadedNodesListener: dependency.downloadedNodesListener,
                    selectionHandler: dependency.selectionHandler,
                    nodeActionHandler: dependency.nodeActionHandler,
                    moreActionsPresenter: dependency.moreActionsPresenter,
                    photoLibraryContentViewRouter: dependency.photoLibraryContentViewRouter,
                    transferIndicatorToolbarFactory: dependency.transferIndicatorToolbarFactory
                )
            )
        case let .bucketItems(bucket):
            RecentActionBucketItemsView(
                dependency: RecentActionBucketItemsView.Dependency(
                    bucket: bucket,
                    resultMapper: dependency.recentActionBucketItemResultMapper,
                    downloadedNodesListener: dependency.downloadedNodesListener,
                    selectionHandler: dependency.selectionHandler,
                    nodeActionHandler: dependency.nodeActionHandler,
                    moreActionsPresenter: dependency.moreActionsPresenter
                )
            )
        case let .multipleMedia(headerTitle, bucket):
            RecentActionBucketMediaView(
                headerTitle: headerTitle,
                bucket: bucket,
                dependency: RecentActionBucketMediaView.Dependency(
                    router: dependency.photoLibraryContentViewRouter,
                    nodeActionHandler: dependency.nodeActionHandler,
                    moreActionsPresenter: dependency.moreActionsPresenter,
                    transferIndicatorToolbarFactory: dependency.transferIndicatorToolbarFactory
                )
            )
        }
    }
}
