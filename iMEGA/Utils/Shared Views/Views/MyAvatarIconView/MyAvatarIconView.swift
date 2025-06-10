import MEGADesignToken
import MEGAL10n
import SwiftUI

struct MyAvatarIconView<AvatarObserver: MyAvatarObserver>: View {
    @StateObject var viewModel: MyAvatarIconViewModel<AvatarObserver>
    
    private let avatarSize: CGFloat = 28
    private let badgeHeight: CGFloat = 20
    
    var body: some View {
        Button {
            viewModel.openUserProfile()
        } label: {
            Image(uiImage: viewModel.avatar)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: avatarSize, height: avatarSize)
                .clipShape(Circle())
        }
        .accessibilityLabel(Strings.Localizable.myAccount)
        .buttonStyle(PlainButtonStyle())
        .overlay(alignment: .topTrailing, content: {
            if let badgeText = viewModel.text, !badgeText.isEmpty {
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
        .onAppear {
            viewModel.onAppear()
        }
    }
}
