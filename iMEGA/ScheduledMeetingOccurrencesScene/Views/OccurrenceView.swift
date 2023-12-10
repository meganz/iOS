import SwiftUI

struct OccurrenceView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let occurrence: ScheduleMeetingOccurrence
    let chatRoomAvatarViewModel: ChatRoomAvatarViewModel?

    private enum Constants {
        static let headerHeight: CGFloat = 28
        static let rowHeight: CGFloat = 65
        static let avatarSize = CGSize(width: 28, height: 28)
        static let spacing: CGFloat = 0
        static let headerSpacing: CGFloat = 4
        static let headerBackgroundOpacity: CGFloat = 0.95
        static let headerTitleOpacity: CGFloat = 0.6
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.spacing) {
            VStack(alignment: .leading, spacing: Constants.headerSpacing) {
                Spacer()
                Text(occurrence.date)
                    .padding(.horizontal)
                    .font(.footnote)
                    .foregroundColor(colorScheme == .dark ? MEGAAppColor.Gray._EBEBF5.color.opacity(Constants.headerTitleOpacity) : MEGAAppColor.Gray._3C3C43.color.opacity(Constants.headerTitleOpacity))
                Divider()
                    .background(colorScheme == .dark ? MEGAAppColor.Gray._545458.color : MEGAAppColor.Gray._3C3C43.color)
            }
            .background(colorScheme == .dark ? MEGAAppColor.Gray._1D1D1D.color.opacity(Constants.headerBackgroundOpacity) : Color(UIColor.whiteF7F7F7).opacity(Constants.headerBackgroundOpacity))
            .frame(height: Constants.headerHeight)

            HStack(alignment: .center) {
                if let chatRoomAvatarViewModel {
                    ChatRoomAvatarView(viewModel: chatRoomAvatarViewModel, size: Constants.avatarSize)
                }
                VStack(alignment: .leading) {
                    Text(occurrence.title)
                        .font(.subheadline)
                    Text(occurrence.time)
                        .font(.caption)
                        .foregroundColor(colorScheme == .dark ? MEGAAppColor.Gray._D1D1D1.color : MEGAAppColor.Gray._515151.color)
                }
            }
            .frame(height: Constants.rowHeight)
        }
        .listRowInsets(EdgeInsets())
    }
}
