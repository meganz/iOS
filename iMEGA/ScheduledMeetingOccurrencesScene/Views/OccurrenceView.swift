import SwiftUI

struct OccurrenceView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let occurrence: ScheduleMeetingOccurence
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
                    .foregroundColor(colorScheme == .dark ? Color(Colors.General.Gray.ebebf5.color).opacity(Constants.headerTitleOpacity) : Color(Colors.General.Gray._3C3C43.color).opacity(Constants.headerTitleOpacity))
                Divider()
                    .background(colorScheme == .dark ? Color(Colors.General.Gray._545458.color) : Color(Colors.General.Gray._3C3C43.color))
            }
            .background(colorScheme == .dark ? Color(Colors.General.Gray._1D1D1D.color).opacity(Constants.headerBackgroundOpacity) : Color(Colors.General.White.f7F7F7.color).opacity(Constants.headerBackgroundOpacity))
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
                        .foregroundColor(colorScheme == .dark ? Color(Colors.General.Gray.d1D1D1.color) : Color(Colors.General.Gray._515151.color))
                }
            }
            .frame(height: Constants.rowHeight)
        }
        .listRowInsets(EdgeInsets())
    }
}
