import MEGADesignToken
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
                    .foregroundColor(dateTextColor)
                Divider()
                    .background(dividerColor)
            }
            .background(backgroundColor)
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
                        .foregroundColor(timeTextColor)
                }
            }
            .frame(height: Constants.rowHeight)
        }
        .listRowInsets(EdgeInsets())
    }
    
    var dateTextColor: Color {
        if isDesignTokenEnabled {
            TokenColors.Text.secondary.swiftUI
        } else {
            colorScheme == .dark ? UIColor.grayEBEBF5.swiftUI.opacity(Constants.headerTitleOpacity) : UIColor.gray3C3C43.swiftUI.opacity(Constants.headerTitleOpacity)
        }
    }

    var dividerColor: Color {
        if isDesignTokenEnabled {
            TokenColors.Border.subtle.swiftUI
        } else {
            colorScheme == .dark ?
                UIColor.gray545458.swiftUI :
                UIColor.gray3C3C43.swiftUI
        }
    }

    var backgroundColor: Color {
        if isDesignTokenEnabled {
            TokenColors.Background.surface1.swiftUI
        } else {
            colorScheme == .dark ? UIColor.gray1D1D1D.swiftUI.opacity(Constants.headerBackgroundOpacity) : UIColor.whiteF7F7F7.swiftUI.opacity(Constants.headerBackgroundOpacity)
        }
    }

    var timeTextColor: Color {
        if isDesignTokenEnabled {
            TokenColors.Text.primary.swiftUI
        } else {
            colorScheme == .dark ?
                UIColor.grayD1D1D1.swiftUI :
                UIColor.gray515151.swiftUI
        }
    }
}
