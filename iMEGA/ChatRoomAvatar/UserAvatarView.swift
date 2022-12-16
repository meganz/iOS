import SwiftUI

struct UserAvatarView: View {
    @ObservedObject var viewModel: UserAvatarViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.layoutDirection) private var layoutDirection

    let size: CGSize
    
    var body: some View {
        ZStack {
            if let primaryAvatar = viewModel.primaryAvatar {
                Image(uiImage: primaryAvatar)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipShape(Circle())
            } else {
                Image(systemName: "circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipShape(Circle())
                    .redacted(reason: .placeholder)
            }
        }
        .padding(8)
        .onAppear {
            viewModel.loadData(isRightToLeftLanguage: layoutDirection == .rightToLeft)
        }
    }
}
