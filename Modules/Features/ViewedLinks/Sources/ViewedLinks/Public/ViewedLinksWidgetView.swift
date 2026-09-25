import Foundation
import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

public struct ViewedLinksWidgetView: View {
    public struct Dependency {
        let viewedLinksUseCase: any ViewedLinksUseCaseProtocol
        let openLink: @MainActor (URL) -> Void
        let onOpenFullScreen: @MainActor () -> Void

        public init(
            viewedLinksUseCase: some ViewedLinksUseCaseProtocol,
            openLink: @escaping @MainActor (URL) -> Void,
            onOpenFullScreen: @escaping @MainActor () -> Void
        ) {
            self.viewedLinksUseCase = viewedLinksUseCase
            self.openLink = openLink
            self.onOpenFullScreen = onOpenFullScreen
        }
    }

    private let dependency: Dependency
    @StateObject private var viewModel: ViewedLinksWidgetViewModel

    public init(dependency: Dependency) {
        self.dependency = dependency
        _viewModel = StateObject(
            wrappedValue: ViewedLinksWidgetViewModel(
                viewedLinksUseCase: dependency.viewedLinksUseCase
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
        HStack(spacing: TokenSpacing._3) {
            Text(Strings.Localizable.Home.Customization.Widget.viewedLinks)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)

            Spacer()

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
        }
        .opacity(isLoaded ? 1 : 0)
        .disabled(!isLoaded)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ViewedLinksWidgetLoadingView()
        case .loaded(let rows):
            VStack(spacing: 0) {
                ForEach(rows) { row in
                    ViewedLinkWidgetRowView(link: row) {
                        dependency.openLink(row.linkURL)
                    }
                }
            }
        case .empty:
            ViewedLinksWidgetEmptyView()
        }
    }
}
