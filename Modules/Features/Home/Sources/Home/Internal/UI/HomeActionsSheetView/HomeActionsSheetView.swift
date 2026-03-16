import MEGADesignToken
import SwiftUI

struct HomeMenuActionsSheetView: View {
    private let menuActions: [HomeAddMenuAction]
    private let actionHandler: any HomeAddMenuActionHandling
    // Binding variable to dismiss the sheet upon action selection.
    @Binding var isPresented: Bool
    @State private var savedAction: HomeAddMenuAction?

    public init(
        menuActions: [HomeAddMenuAction] = HomeAddMenuAction.allCases,
        actionHandler: some HomeAddMenuActionHandling,
        isPresented: Binding<Bool>,
    ) {
        self.menuActions = menuActions
        self.actionHandler = actionHandler
        _isPresented = isPresented
    }

    public var body: some View {
        GeometryReader { proxy in
            ScrollView {
                LazyVStack(spacing: .zero) {
                    ForEach(menuActions) { action in
                        UploadActionItemView(
                            image: action.image,
                            title: action.title,
                            actionHandler: {
                                isPresented = false
                                savedAction = action
                            })
                    }
                }
                .padding(.top, TokenSpacing._6)
            }
            .scrollDisabled(!scrollingEnabled(in: proxy))
            // We need calculate the detent height so that the sheet will tightly wrap around the list of contents and prevent
            // the sheet from getting expanded when user swipes up.
            // Also since we're using custom height for detent, we need to account for the bottom safe area.
            .presentationDetents([.height(allActionsHeight + proxy.safeAreaInsets.bottom)])
        }
        .onDisappear {
            guard let savedAction else { return }
            actionHandler.handleAction(savedAction)
        }
        .presentationDragIndicator(.visible)
    }

    private func scrollingEnabled(in proxy: GeometryProxy) -> Bool {
        allActionsHeight > proxy.size.height
    }

    private var allActionsHeight: CGFloat {
        CGFloat(menuActions.count) * UploadActionItemView.Constants.itemHeight
    }
}

private struct UploadActionItemView: View {
    enum Constants {
        static let imageSize: CGFloat = 24
        static let itemHeight: CGFloat = 58

    }
    let image: Image
    let title: String

    let actionHandler: @MainActor () -> Void

    var body: some View {
        Button {
            actionHandler()
        } label: {
            HStack(spacing: TokenSpacing._4) {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Constants.imageSize, height: Constants.imageSize)
                    .foregroundStyle(TokenColors.Icon.primary.swiftUI)

                Text(title)
                    .font(.body)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                Spacer()
            }
        }
        .padding(.leading, TokenSpacing._6)
        .frame(height: Constants.itemHeight)
    }
}
