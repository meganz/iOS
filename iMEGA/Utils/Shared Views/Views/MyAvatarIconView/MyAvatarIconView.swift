import MEGADesignToken
import MEGAL10n
import SwiftUI

struct MyAvatarIconView: View {
    @StateObject var viewModel: MyAvatarIconViewModel = MyAvatarIconViewModel(avatarObserver: MyAvatarObserver.shared)
    
    private let avatarSize: CGFloat = 28
    private let badgeHeight: CGFloat = 20
    private let action: @MainActor () -> Void
    
    init(action: @escaping @MainActor () -> Void) {
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            avatarView
        }
        .accessibilityLabel(Strings.Localizable.myAccount)
        .buttonStyle(PlainButtonStyle())
        .overlay(alignment: .topTrailing, content: {
            if let badgeText = viewModel.badge, !badgeText.isEmpty {
                Text(badgeText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(EdgeInsets(top: 3, leading: 2, bottom: 3, trailing: 2))
                    .frame(minWidth: badgeHeight)
                    .background(alignment: .center) {
                        RoundedRectangle(cornerRadius: badgeHeight / 2, style: .continuous)
                            .fill(TokenColors.Components.interactive.swiftUI)
                            .frame(minWidth: badgeHeight)
                    }
                    .fixedSize()
                    .position(x: avatarSize, y: badgeHeight / 2)
            }
        })
        .task {
            await viewModel.onAppear()
        }
    }
    
    @ViewBuilder
    private var avatarView: some View {
        if let avatar = viewModel.avatar {
            Image(uiImage: avatar)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: avatarSize, height: avatarSize)
                .clipShape(Circle())
        } else {
            Text(viewModel.avatarInitial)
                .font(.system(size: avatarSize / 2))
                .foregroundStyle(TokenColors.Text.onColor.swiftUI)
                .frame(width: avatarSize, height: avatarSize)
                .background(alignment: .center) {
                    Circle()
                        .fill(viewModel.avatarBackgroundColor)
                }
        }
    }
}
