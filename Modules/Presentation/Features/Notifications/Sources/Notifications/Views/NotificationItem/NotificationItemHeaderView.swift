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
                        isDesignTokenEnabled: isDesignTokenEnabled,
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
                        isDesignTokenEnabled: isDesignTokenEnabled,
                        isDarkMode: colorScheme == .dark
                    ),
                    tagTextColor: tag.textColor(
                        isDesignTokenEnabled: isDesignTokenEnabled,
                        isDarkMode: colorScheme == .dark
                    ),
                    cornerRadius: 4
                )
            }
        }
        .padding(.bottom, 8)
    }
}
