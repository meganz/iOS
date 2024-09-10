import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct NotificationItemHeaderView: View {
    let type: NotificationType
    let tag: NotificationTag
    
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack {
            Text(type.displayName)
                .foregroundStyle(
                    type.textColor(
                        isDarkMode: colorScheme == .dark
                    )
                )
                .font(.caption2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if tag != .none {
                Spacer()
                
                TagView(
                    tagName: tag.displayName,
                    tagColor: tag.bgColor(
                        isDarkMode: colorScheme == .dark
                    ),
                    tagTextColor: tag.textColor(
                        isDarkMode: colorScheme == .dark
                    ),
                    cornerRadius: 4,
                    paddingInsets: EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8),
                    font: .caption2
                )
            }
        }
        .padding(.bottom, 8)
    }
}
