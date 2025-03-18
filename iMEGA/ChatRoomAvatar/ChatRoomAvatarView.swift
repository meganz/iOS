import SwiftUI

struct ChatRoomAvatarView: View {
    @ObservedObject var viewModel: ChatRoomAvatarViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.layoutDirection) private var layoutDirection

    let size: CGSize
    
    private let offsetValue: CGFloat = 6
    private var totalOffset: CGFloat { offsetValue * 2 }
    
    var body: some View {
        ZStack {
            if case let .two(primaryAvatar, secondaryAvatar) = viewModel.avatarType {
                Image(uiImage: secondaryAvatar)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipShape(Circle())
                    .offset(x: -offsetValue, y: -offsetValue)
                
                Image(uiImage: primaryAvatar)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                colorScheme == .dark ?
                                    Color(uiColor: .black000000) :
                                    Color(uiColor: .whiteFFFFFF),
                                lineWidth: 1
                            )
                    )
                    .offset(x: offsetValue, y: offsetValue)
            } else if case let .one(avatar) = viewModel.avatarType {
                Image(uiImage: avatar)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width + offsetValue, height: size.height + offsetValue)
                    .clipShape(Circle())
            } else if case let .noteToSelf(avatar) = viewModel.avatarType {
                Image(uiImage: avatar)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .clipShape(Circle())
            } else if case let .placeHolder(name) = viewModel.avatarType {
                Image(systemName: name)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width + offsetValue, height: size.height + offsetValue)
                    .clipShape(Circle())
                    .redacted(reason: .placeholder)
            }
        }
        .frame(width: size.width + totalOffset, height: size.height + totalOffset)
        .padding(8)
        .task(priority: .background) {
            await viewModel.loadAvatar(isRightToLeftLanguage: layoutDirection == .rightToLeft)
        }
    }
}
