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
            if let secondaryAvatar = viewModel.secondaryAvatar,
               let primaryAvatar = viewModel.primaryAvatar {
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
                            .stroke(colorScheme == .dark ? Color.black : Color.white, lineWidth: 1)
                    )
                    .offset(x: offsetValue, y: offsetValue)
            } else if let primaryAvatar = viewModel.primaryAvatar {
                Image(uiImage: primaryAvatar)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width + offsetValue, height: size.height + offsetValue)
                    .clipShape(Circle())
            } else {
                Image(systemName: "circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width + offsetValue, height: size.height + offsetValue)
                    .clipShape(Circle())
                    .redacted(reason: .placeholder)
            }
        }
        .frame(width: size.width + totalOffset, height: size.height + totalOffset)
        .padding(8)
        .onAppear {
            viewModel.loadData(isRightToLeftLanguage: layoutDirection == .rightToLeft)
        }
    }
}
