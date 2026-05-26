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

            moreOptionsMenu
        }
        .padding(.bottom, TokenSpacing._3)
        .padding(.horizontal, TokenSpacing._5)
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
                nodeActionHandler: dependency.nodeActionHandler,
                moreActionsPresenter: dependency.moreActionsPresenter,
                photoLibraryContentViewRouter: dependency.photoLibraryContentViewRouter,
                transferIndicatorToolbarFactory: dependency.transferIndicatorToolbarFactory
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

private struct LegacyRecentsLoadingContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._3) {
            ForEach(0..<2, id: \.self) { _ in
                HStack(spacing: TokenSpacing._4) {
                    RoundedRectangle(cornerRadius: 6)
                        .frame(width: 32, height: 32)

                    VStack(alignment: .leading, spacing: TokenSpacing._1) {
                        Text(String(repeating: " ", count: 20))
                            .font(.subheadline)

                        Text(String(repeating: " ", count: 12))
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.horizontal, TokenSpacing._5)
        .padding(.vertical, TokenSpacing._3)
        .redacted(reason: .placeholder)
        .shimmering()
    }
}

private struct RecentsLoadingContentView: View {
    private enum Constants {
        static let iconSize: CGFloat = 32
        static let iconCornerRadius: CGFloat = 6
        static let lineCornerRadius: CGFloat = 4
        static let titleHeight: CGFloat = 16
        static let subtitleHeight: CGFloat = 12
        static let sectionLabelWidth: CGFloat = 62
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._4) {
            RoundedRectangle(cornerRadius: Constants.lineCornerRadius)
                .frame(width: Constants.sectionLabelWidth, height: Constants.titleHeight)
            recentRow(extraSubtitleLines: 0)
            recentRow(extraSubtitleLines: 0)

            RoundedRectangle(cornerRadius: Constants.lineCornerRadius)
                .frame(width: Constants.sectionLabelWidth, height: Constants.titleHeight)
            recentRow(extraSubtitleLines: 1)
            recentRow(extraSubtitleLines: 1)
        }
        .padding(.horizontal, TokenSpacing._5)
        .padding(.vertical, TokenSpacing._3)
        .redacted(reason: .placeholder)
        .shimmering()
    }

    private func recentRow(extraSubtitleLines: Int) -> some View {
        HStack(spacing: TokenSpacing._4) {
            RoundedRectangle(cornerRadius: Constants.iconCornerRadius)
                .frame(width: Constants.iconSize, height: Constants.iconSize)

            VStack(alignment: .leading, spacing: TokenSpacing._1) {
                RoundedRectangle(cornerRadius: Constants.lineCornerRadius)
                    .frame(maxWidth: .infinity)
                    .frame(height: Constants.titleHeight)

                ForEach(0..<(extraSubtitleLines + 1), id: \.self) { _ in
                    RoundedRectangle(cornerRadius: Constants.lineCornerRadius)
                        .frame(maxWidth: .infinity)
                        .frame(height: Constants.subtitleHeight)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
