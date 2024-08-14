import MEGADesignToken
import MEGAL10n
import SwiftUI

struct ChatTabsSelectorView: View {
    @Environment(\.colorScheme) private var colorScheme
    var chatViewMode: ChatViewMode
    let shouldDisplayUnreadBadgeForChats: Bool
    let shouldDisplayUnreadBadgeForMeetings: Bool
    var action: (ChatViewMode) -> Void

    var body: some View {
        HStack(spacing: 0) {
            VStack {
                Spacer()
                Button(action: {
                    action(.chats)
                }, label: {
                    Text(Strings.Localizable.Chat.Selector.chat)
                        .font(Font.system(.subheadline, design: .default).weight(.medium))
                        .foregroundColor(chatViewMode == .chats ? selectedColor : unselectedColor)
                    
                })
                .overlay(alignment: .trailing, content: {
                    Circle()
                        .fill(isDesignTokenEnabled ? TokenColors.Components.interactive.swiftUI : MEGAAppColor.Red._F30C14_badge.color)
                        .frame(width: 5, height: 5)
                        .offset(x: 9, y: -3)
                        .opacity(shouldDisplayUnreadBadgeForChats ? 1 : 0)
                })
                Divider()
                    .frame(maxHeight: 1)
                    .background(chatViewMode == .chats ? selectedColor : unselectedDividerColor)
                    .opacity(chatViewMode == .chats ? 1 : 0)
            }
            
            VStack {
                Spacer()
                Button(action: {
                    action(.meetings)
                }, label: {
                    Text(Strings.Localizable.Chat.Selector.meeting)
                        .font(Font.system(.subheadline, design: .default).weight(.medium))
                        .foregroundColor(chatViewMode == .meetings ? selectedColor : unselectedColor)
                })
                .overlay(alignment: .trailing, content: {
                    Circle()
                        .fill(isDesignTokenEnabled ? TokenColors.Components.interactive.swiftUI : MEGAAppColor.Red._F30C14_badge.color)
                        .frame(width: 5, height: 5)
                        .offset(x: 9, y: -3)
                        .opacity(shouldDisplayUnreadBadgeForMeetings ? 1 : 0)
                })
                Divider()
                    .frame(maxHeight: 1)
                    .background(chatViewMode == .meetings ? selectedColor : unselectedDividerColor)
                    .opacity(chatViewMode == .meetings ? 1 : 0)
            }
        }
        .frame(maxHeight: 44)
        .background(colorScheme == .dark ? MEGAAppColor.Black._161616.color : MEGAAppColor.White._F7F7F7.color)
    }
    
    private var selectedColor: Color {
        isDesignTokenEnabled ? TokenColors.Button.brand.swiftUI : MEGAAppColor.Chat.chatTabSelectedText.color
    }
    
    private var unselectedColor: Color {
        isDesignTokenEnabled ? TokenColors.Icon.secondary.swiftUI : MEGAAppColor.Chat.chatTabNormalText.color
    }
    
    private var unselectedDividerColor: Color {
        isDesignTokenEnabled ? TokenColors.Icon.secondary.swiftUI : MEGAAppColor.Chat.chatTabNormalBackground.color
    }
}
