import ContentLibraries
import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import Search
import SwiftUI
import Transfer

struct RecentActionBucketsListView: View {
    struct Dependency {
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
        case bucketItems(RecentActionBucketEntity)
        case multipleMedia(String, RecentActionBucketEntity)
    }

    private enum CarouselSheetDeferredAction {
        case openNode(handle: HandleEntity, siblings: [HandleEntity])
        case showInLocation(HandleEntity)
        case seeAll(RecentActionBucketEntity)
    }

    private let dependency: Dependency
    @StateObject private var viewModel = RecentActionBucketsListViewModel()
    @EnvironmentObject var navigator: HomeNavigation
    @State private var carouselBucket: RecentActionBucketEntity?
    @State private var carouselSectionTitle: String?
    @State private var carouselDeferredAction: CarouselSheetDeferredAction?
    
    init(dependency: Dependency) {
        self.dependency = dependency
    }
    
    var body: some View {
        content
            .navigationTitle(Strings.Localizable.recents)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    BackButton()
                }
                
                dependency.transferIndicatorToolbarFactory.toolbarContent(trailingItemCount: 1)

                ToolbarItem(placement: .topBarTrailing) {
                    moreOptionsButton
                }
            }
            .background(TokenColors.Background.page.swiftUI)
            .navigationDestination(for: Route.self) { route in
                navigationDestination(for: route)
            }
            .confirmClearRecentActivityAlert(isPresented: $viewModel.isConfirmingClearRecentActivity) {
                Task {
                    await viewModel.clearRecentActivity()
                    navigator.removeLast()
                }
            }
            .onDisappear {
                if let message = viewModel.recentActivityHiddenSnackBarMessage {
                    navigator.showSnackBar(SnackBar(message: message))
                }
                
                if let message = viewModel.recentActivityClearedSnackBarMessage {
                    navigator.showSnackBar(SnackBar(message: message))
                }
            }
            .sheet(isPresented: carouselSheetBinding, onDismiss: { performDeferredCarouselAction() }, content: { carouselSheetContent })
    }
    
    @ViewBuilder
    private var content: some View {
        Group {
            switch viewModel.viewState {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(TokenColors.Background.page.swiftUI)
            case let .results(sections):
                resultsContent(sections: sections)
            }
        }
        .miniPlayerAware()
        .task {
            await viewModel.onLoad()
            await viewModel.observeRecentBucketUpdates()
        }
    }
    
    @ViewBuilder func resultsContent(sections: [RecentActionBucketSection]) -> some View {
        if #available(iOS 17.0, *) {
            bucketsContent(sections: sections)
                .listSectionSpacing(0)
        } else {
            bucketsContent(sections: sections)
        }
    }
    
    private var moreOptionsButton: some View {
        Menu {
            HideRecentActivityMenuItemView {
                viewModel.hideRecentActivity()
                navigator.removeLast()
            }
            
            ClearRecentActivityMenuItemView {
                viewModel.confirmClearRecentActivity()
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
