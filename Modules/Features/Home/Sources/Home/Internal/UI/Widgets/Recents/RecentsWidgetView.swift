import ContentLibraries
import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import Search
import SwiftUI
import Transfer

struct RecentsWidgetView: View {
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
    
    private let supportedMenuActions: [HomeAddMenuAction] = [
        .chooseFromPhotos,
        .capture,
        .importFromFiles,
        .scanDocument,
        .newTextFile
    ]
    
    private let dependency: Dependency
    @State private var presentsSheet = false
    @StateObject private var viewModel: RecentsWidgetViewModel
    @State private var confirmingClearRecentActivity = false
    @EnvironmentObject var navigator: HomeNavigation
    private let addMenuActionHandler: any HomeAddMenuActionHandling

    init(dependency: Dependency, addMenuActionHandler: some HomeAddMenuActionHandling) {
        self.addMenuActionHandler = addMenuActionHandler
        self.dependency = dependency
        _viewModel = StateObject(
            wrappedValue: RecentsWidgetViewModel()
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .padding(.vertical, TokenSpacing._4)
        .task {
            await viewModel.onTask()
        }
        .sheet(isPresented: $presentsSheet) {
            HomeMenuActionsSheetView(
                menuActions: supportedMenuActions,
                actionHandler: addMenuActionHandler,
                isPresented: $presentsSheet
            )
        }
        .confirmClearRecentActivityAlert(isPresented: $confirmingClearRecentActivity) {
            Task {
                guard let message = await viewModel.clearRecentActivity() else { return }
                navigator.showSnackBar(SnackBar(message: message))
            }
        }
    }

    private var header: some View {
        HStack(spacing: TokenSpacing._3) {
            Text(Strings.Localizable.recents)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)

            Spacer()

            if dependency.isHomeRevampPhaseTwoEnabled {
                viewAllChevronButton
            } else {
                moreOptionsMenu
            }
        }
        .padding(.bottom, TokenSpacing._3)
        .padding(.horizontal, TokenSpacing._5)
    }

    @ViewBuilder
    private var viewAllChevronButton: some View {
        if case .nonEmpty = viewModel.state {
            Button {
                viewModel.trackViewAllTapped()
                navigator.append(RecentWidgetBucketListView.Route.viewAllBuckets)
            } label: {
                MEGAAssets.Image.chevronRight
                    .renderingMode(.template)
                    .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                    .frame(width: 24, height: 24)
            }
        }
    }

    @ViewBuilder
    private var moreOptionsMenuLabel: some View {
        Button(
           action: {},
           label: {
               Label {
                   Text(Strings.Localizable.more)
               } icon: {
                   MEGAAssets.Image.moreHorizontal
                       .renderingMode(.template)
                       .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                       .frame(width: 24, height: 24)
               }
               .labelStyle(.iconOnly)
           }
        )
    }

    @ViewBuilder
    private var moreOptionsMenu: some View {
        switch viewModel.state {
        case .hidden:
            Menu {
                ShowRecentActivityMenuItemView {
                    Task {
                        await viewModel.didTapShowActivityButton()
                    }
                }
                ClearRecentActivityMenuItemView {
                    confirmingClearRecentActivity = true
                }
            } label: {
                moreOptionsMenuLabel
            }

        case .empty:
            Menu {
                HideRecentActivityMenuItemView {
                    Task {
                        await viewModel.hideRecentActivity()
                        navigator.showSnackBar(SnackBar(message: Strings.Localizable.Home.Recent.HideRecentActivity.Snackbar.message))
                    }
                }
            } label: {
                moreOptionsMenuLabel
            }

        case .nonEmpty:
            Menu {
                HideRecentActivityMenuItemView {
                    Task {
                        await viewModel.hideRecentActivity()
                        navigator.showSnackBar(SnackBar(message: Strings.Localizable.Home.Recent.HideRecentActivity.Snackbar.message))
                    }
                }

                ClearRecentActivityMenuItemView {
                    confirmingClearRecentActivity = true
                }
            } label: {
                moreOptionsMenuLabel
            }
        case .error, .loading:
            EmptyView()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            if dependency.isHomeRevampPhaseTwoEnabled {
                RecentsLoadingContentView()
            } else {
                LegacyRecentsLoadingContentView()
            }
        case let .nonEmpty(bucketGroups):
            nonEmptyContent(bucketGroups: bucketGroups)
        case .empty:
            EmptyRecentsContentView {
                presentsSheet = true
            }
        case .hidden:
            HiddenRecentsContentView {
                Task {
                    await viewModel.didTapShowActivityButton()
                }
            }
        case .error:
            ErrorRecentsContentView {
                Task {
                    await viewModel.didTapRetryButton()
                }
            }
        }
    }

    private func nonEmptyContent(bucketGroups: [DailyRecentActionBucketGroup]) -> RecentWidgetBucketListView {
        RecentWidgetBucketListView(
            dependency: RecentWidgetBucketListView.Dependency(
                bucketGroups: bucketGroups,
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
    }
}

private struct HiddenRecentsContentView: View {
    let showActivityAction: @MainActor () -> Void

    var body: some View {
        HStack(spacing: TokenSpacing._4) {
            VStack(alignment: .leading, spacing: TokenSpacing._1) {
                Text(Strings.Localizable.Recents.EmptyState.ActivityHidden.title)
                    .font(.footnote)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                    .frame(maxWidth: .infinity, alignment: .leading)

                showActivityButton
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, TokenSpacing._3)

            MEGAAssets.Image.recentsClock
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
        }
        .padding(.horizontal, TokenSpacing._5)
    }

    private var showActivityButton: some View {
        Button {
            showActivityAction()
        } label: {
            Text(Strings.Localizable.Recents.EmptyState.ActivityHidden.button)
                .font(.callout)
                .fontWeight(.semibold)
                .underline()
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .frame(height: 32, alignment: .center)
        }
    }
}

private struct ErrorRecentsContentView: View {
    let retryAction: @MainActor () -> Void

    var body: some View {
        HStack(spacing: TokenSpacing._4) {
            VStack(alignment: .leading, spacing: TokenSpacing._1) {
                Text(Strings.Localizable.Home.Recent.Widget.Error.message)
                    .font(.footnote)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                    .frame(maxWidth: .infinity, alignment: .leading)

                retryButton
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, TokenSpacing._3)

            MEGAAssets.Image.recentsClock
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
        }
        .padding(.horizontal, TokenSpacing._5)
    }

    private var retryButton: some View {
        Button {
            retryAction()
        } label: {
            Text(Strings.Localizable.retry)
                .font(.callout)
                .fontWeight(.semibold)
                .underline()
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .frame(height: 32, alignment: .center)
        }
    }
}

private enum RecentsSkeleton {
    static let color = TokenColors.Text.primary.swiftUI
    static let iconSize: CGFloat = 32
}

private extension View {
    func recentsSkeletonContainer() -> some View {
        padding(.horizontal, TokenSpacing._5)
            .padding(.vertical, TokenSpacing._3)
            .shimmering()
            .allowsHitTesting(false)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Strings.Localizable.loading)
    }
}

private struct RecentsSkeletonIcon: View {
    var body: some View {
        RoundedRectangle(cornerRadius: TokenRadius.medium)
            .fill(RecentsSkeleton.color)
            .frame(width: RecentsSkeleton.iconSize, height: RecentsSkeleton.iconSize)
    }
}

private struct RecentsSkeletonLine: View {
    enum Style {
        case title
        case subtitle

        var metrics: (height: CGFloat, textStyle: Font.TextStyle) {
            switch self {
            case .title: (16, .subheadline)
            case .subtitle: (12, .caption)
            }
        }
    }

    private let width: CGFloat?
    @ScaledMetric private var height: CGFloat

    init(_ style: Style, width: CGFloat? = nil) {
        self.width = width
        _height = ScaledMetric(wrappedValue: style.metrics.height, relativeTo: style.metrics.textStyle)
    }

    var body: some View {
        RoundedRectangle(cornerRadius: TokenRadius.small)
            .fill(RecentsSkeleton.color)
            .frame(width: width, height: height)
    }
}

private struct LegacyRecentsLoadingContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._3) {
            ForEach(0..<2, id: \.self) { _ in
                HStack(spacing: TokenSpacing._4) {
                    RecentsSkeletonIcon()

                    VStack(alignment: .leading, spacing: TokenSpacing._1) {
                        RecentsSkeletonLine(.title, width: 156)
                        RecentsSkeletonLine(.subtitle, width: 81)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .recentsSkeletonContainer()
    }
}

private struct RecentsLoadingContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._4) {
            RecentsSkeletonLine(.title, width: 62)
            recentRow(extraSubtitleLines: 0)
            recentRow(extraSubtitleLines: 0)

            RecentsSkeletonLine(.title, width: 62)
            recentRow(extraSubtitleLines: 1)
            recentRow(extraSubtitleLines: 1)
        }
        .recentsSkeletonContainer()
    }

    private func recentRow(extraSubtitleLines: Int) -> some View {
        HStack(spacing: TokenSpacing._4) {
            RecentsSkeletonIcon()

            VStack(alignment: .leading, spacing: TokenSpacing._1) {
                RecentsSkeletonLine(.title)

                ForEach(0..<(extraSubtitleLines + 1), id: \.self) { _ in
                    RecentsSkeletonLine(.subtitle)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
