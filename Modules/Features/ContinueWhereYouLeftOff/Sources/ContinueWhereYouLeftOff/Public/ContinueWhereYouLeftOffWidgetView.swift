import Foundation
import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import SwiftUI

public struct ContinueWhereYouLeftOffWidgetView: View {
    public struct Dependency {
        let leftOffItemsUseCase: any LeftOffItemsUseCaseProtocol
        let thumbnailLoader: any ThumbnailLoaderProtocol
        let selectionHandler: any NodeSelectionHandling
        let onOpenFullScreen: @MainActor () -> Void

        public init(
            leftOffItemsUseCase: some LeftOffItemsUseCaseProtocol,
            thumbnailUseCase: some ThumbnailUseCaseProtocol,
            selectionHandler: some NodeSelectionHandling,
            onOpenFullScreen: @escaping @MainActor () -> Void
        ) {
            self.leftOffItemsUseCase = leftOffItemsUseCase
            self.thumbnailLoader = ThumbnailLoaderFactory.makeThumbnailLoader(config: .general, thumbnailUseCase: thumbnailUseCase)
            self.selectionHandler = selectionHandler
            self.onOpenFullScreen = onOpenFullScreen
        }
    }

    private let dependency: Dependency
    @State private var viewModel: LeftOffItemsCarouselViewModel

    public init(dependency: Dependency) {
        self.dependency = dependency
        _viewModel = State(
            wrappedValue: LeftOffItemsCarouselViewModel(
                leftOffItemsUseCase: dependency.leftOffItemsUseCase
            )
        )
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .padding(.vertical, TokenSpacing._4)
        .task {
            await viewModel.onTask()
        }
    }

    private var header: some View {
        HStack(spacing: 0) {
            Text(Strings.Localizable.Home.Customization.Widget.continueWhereYouLeftOff)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .layoutPriority(1)
            chevronButton
        }
        .padding(.bottom, TokenSpacing._3)
        .padding(.horizontal, TokenSpacing._5)
    }

    private var isLoaded: Bool {
        if case .loaded = viewModel.state { true } else { false }
    }

    private var chevronButton: some View {
        Button(action: dependency.onOpenFullScreen) {
            MEGAAssets.Image.chevronRight
                .renderingMode(.template)
                .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                .frame(width: TokenSpacing._7, height: TokenSpacing._7)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .contentShape(Rectangle())
        }
        .opacity(isLoaded ? 1 : 0)
        .disabled(!isLoaded)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            LeftOffItemsWidgetLoadingView()
        case .loaded(let items, let hasMore, let isLoadingMore):
            LeftOffItemsCarouselView(
                items: items,
                hasMore: hasMore,
                isLoadingMore: isLoadingMore,
                thumbnailLoader: dependency.thumbnailLoader,
                onOpenItem: { card in
                    dependency.selectionHandler.handle(selection: NodeSelection(handle: card.node.handle, siblings: []))
                },
                onLoadMore: { Task { await viewModel.loadMore() } }
            )
        case .empty:
            LeftOffItemsWidgetEmptyView()
        }
    }
}
