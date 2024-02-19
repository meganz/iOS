import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct NotificationItemHeaderView: View {
    let typeName: String
    let typeColor: Color
    let tag: NotificationTag
    
    @Environment(\.colorScheme) var colorScheme
    private var tagColor: Color {
        colorScheme == .dark ? Color(red: 0, green: 0.761, blue: 0.604) : Color(red: 0, green: 0.659, blue: 0.525)
    }

    var body: some View {
        HStack {
            Text(typeName)
                .foregroundStyle(typeColor)
                .font(.caption2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if tag != .none {
                Spacer()
                
                TagView(
                    tagName: tag.displayName,
                    tagColor: isDesignTokenEnabled ? TokenColors.Support.success.swiftUI : tagColor,
                    tagTextColor: isDesignTokenEnabled ? TokenColors.Text.onColor.swiftUI : .white,
                    cornerRadius: 4
                )
            }
        }
    }
}
