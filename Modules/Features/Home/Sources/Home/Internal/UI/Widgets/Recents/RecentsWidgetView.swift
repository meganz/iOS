import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

struct RecentsWidgetView: View {
    struct Dependency {
        let userNameProvider: any UserNameProviderProtocol
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

    private let addMenuActionHandler: any HomeAddMenuActionHandling

    init(dependency: Dependency, addMenuActionHandler: some HomeAddMenuActionHandling) {
        self.addMenuActionHandler = addMenuActionHandler
        self.dependency = dependency
        _viewModel = StateObject(
            wrappedValue: RecentsWidgetViewModel(homeRecentsWidgetUseCase: HomeRecentsWidgetUseCase())
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
    }

    private var header: some View {
        HStack(spacing: TokenSpacing._3) {
            Text(Strings.Localizable.recents)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)

            Spacer()

            Button(action: {
                viewModel.didTapMoreButton()
            }, label: {
                Label {
                    Text(Strings.Localizable.more)
                } icon: {
                    MEGAAssets.Image.moreHorizontal
                        .renderingMode(.template)
                        .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                        .frame(width: 24, height: 24)
                }
                .labelStyle(.iconOnly)
            })
        }
        .padding(.bottom, TokenSpacing._3)
        .padding(.horizontal, TokenSpacing._5)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
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
        }
    }

    private func nonEmptyContent(bucketGroups: [DailyRecentActionBucketGroup]) -> some View {
        RecentWidgetBucketListView(
            dependency: RecentWidgetBucketListView.Dependency(
                bucketGroups: bucketGroups,
                userNameProvider: dependency.userNameProvider
            )
        )
    }
}

private struct EmptyRecentsContentView: View {
    let uploadAction: @MainActor () -> Void

    var body: some View {
        HStack(spacing: TokenSpacing._4) {
            VStack(alignment: .leading, spacing: TokenSpacing._1) {
                Text(Strings.Localizable.Recents.EmptyState.Empty.message)
                    .font(.footnote)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                    .frame(maxWidth: .infinity, alignment: .leading)

                uploadButton
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

    private var uploadButton: some View {
        Button {
            uploadAction()
        } label: {
            Text(Strings.Localizable.upload)
                .font(.callout)
                .fontWeight(.semibold)
                .underline()
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .frame(height: 32, alignment: .center)
        }
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
