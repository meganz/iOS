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
        let locationHandler: any NodeLocationHandling
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
    
    private enum CarouselSheetDeferredAction {
        case openNode(handle: HandleEntity, siblings: [HandleEntity])
        case showInLocation(HandleEntity)
        case seeAll(RecentActionBucketEntity)
    }

    private let dependency: Dependency
    private let sections: [RecentActionBucketSection]
    private let recentActionBucketSectionMapper = RecentActionBucketSectionMapper()
    private let viewModel: RecentWidgetBucketListViewModel

    @EnvironmentObject var navigator: HomeNavigation
    @State private var carouselBucket: RecentActionBucketEntity?
    @State private var carouselSectionTitle: String?
    @State private var carouselDeferredAction: CarouselSheetDeferredAction?

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
        .sheet(isPresented: carouselSheetBinding, onDismiss: { performDeferredCarouselAction() }, content: { carouselSheetContent })
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
                            },
                            bucketCarouselPresenter: makeCarouselPresenter(sectionTitle: section.title)
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
                    locationHandler: dependency.locationHandler,
                    nodeActionHandler: dependency.nodeActionHandler,
                    moreActionsPresenter: dependency.moreActionsPresenter,
                    photoLibraryContentViewRouter: dependency.photoLibraryContentViewRouter,
                    transferIndicatorToolbarFactory: dependency.transferIndicatorToolbarFactory,
                    isHomeRevampPhaseTwoEnabled: dependency.isHomeRevampPhaseTwoEnabled
                )
            )
        case let .bucketItems(bucket):
            RecentActionBucketItemsView(
                dependency: RecentActionBucketItemsView.Dependency(
                    bucket: bucket,
                    resultMapper: dependency.recentActionBucketItemResultMapper,
                    downloadedNodesListener: dependency.downloadedNodesListener,
                    selectionHandler: dependency.selectionHandler,
                    locationHandler: dependency.locationHandler,
                    nodeActionHandler: dependency.nodeActionHandler,
                    moreActionsPresenter: dependency.moreActionsPresenter,
                    isHomeRevampPhaseTwoEnabled: dependency.isHomeRevampPhaseTwoEnabled
                )
            )
        case let .multipleMedia(headerTitle, bucket):
            RecentActionBucketMediaView(
                headerTitle: headerTitle,
                bucket: bucket,
                dependency: RecentActionBucketMediaView.Dependency(
                    router: dependency.photoLibraryContentViewRouter,
                    locationHandler: dependency.locationHandler,
                    nodeActionHandler: dependency.nodeActionHandler,
                    moreActionsPresenter: dependency.moreActionsPresenter,
                    transferIndicatorToolbarFactory: dependency.transferIndicatorToolbarFactory,
                    isHomeRevampPhaseTwoEnabled: dependency.isHomeRevampPhaseTwoEnabled
                )
            )
        }
    }

    private func makeCarouselPresenter(sectionTitle: String) -> RecentActionBucketContainerView.BucketCarouselPresenter? {
        guard dependency.isHomeRevampPhaseTwoEnabled else { return nil }
        return { bucket in
            carouselDeferredAction = nil
            carouselSectionTitle = sectionTitle
            carouselBucket = bucket
        }
    }

    private var carouselSheetBinding: Binding<Bool> {
        Binding(
            get: { carouselBucket != nil },
            set: { isPresented in
                if !isPresented {
                    carouselBucket = nil
                }
            }
        )
    }

    @ViewBuilder
    private var carouselSheetContent: some View {
        if let bucket = carouselBucket {
            RecentBucketCarouselSheetView(
                dependency: RecentBucketCarouselSheetView.Dependency(
                    bucket: bucket,
                    actionHandler: { action in
                        switch action {
                        case let .openNode(handle, siblings):
                            carouselDeferredAction = .openNode(handle: handle, siblings: siblings)
                        case let .showInLocation(handle):
                            carouselDeferredAction = .showInLocation(handle)
                        case .seeAll:
                            carouselDeferredAction = .seeAll(bucket)
                        }
                        carouselBucket = nil
                    }
                )
            )
        }
    }

    private func performDeferredCarouselAction() {
        guard let action = carouselDeferredAction else { return }
        carouselDeferredAction = nil
        let sectionTitle = carouselSectionTitle
        carouselSectionTitle = nil
        switch action {
        case let .openNode(handle, siblings):
            dependency.selectionHandler.handle(selection: NodeSelection(handle: handle, siblings: siblings))
        case let .showInLocation(handle):
            dependency.locationHandler.showInLocation(of: handle)
        case let .seeAll(bucket):
            switch bucket.type {
            case .multipleMedia:
                navigator.append(Route.multipleMedia(sectionTitle ?? "", bucket))
            default:
                navigator.append(Route.bucketItems(bucket))
            }
        }
    }
}
