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
                        .foregroundColor(chatViewMode == .chats ? TokenColors.Button.brand.swiftUI : TokenColors.Icon.secondary.swiftUI)
                    
                })
                .overlay(alignment: .trailing, content: {
                    Circle()
                        .fill(TokenColors.Components.interactive.swiftUI)
                        .frame(width: 5, height: 5)
                        .offset(x: 9, y: -3)
                        .opacity(shouldDisplayUnreadBadgeForChats ? 1 : 0)
                })
                Divider()
                    .frame(maxHeight: 1)
                    .background(chatViewMode == .chats ? TokenColors.Button.brand.swiftUI : TokenColors.Icon.secondary.swiftUI)
                    .opacity(chatViewMode == .chats ? 1 : 0)
            }
            
            VStack {
                Spacer()
                Button(action: {
                    action(.meetings)
                }, label: {
                    Text(Strings.Localizable.Chat.Selector.meeting)
                        .font(Font.system(.subheadline, design: .default).weight(.medium))
                        .foregroundColor(chatViewMode == .meetings ? TokenColors.Button.brand.swiftUI : TokenColors.Icon.secondary.swiftUI)
                })
                .overlay(alignment: .trailing, content: {
                    Circle()
                        .fill(TokenColors.Components.interactive.swiftUI)
                        .frame(width: 5, height: 5)
                        .offset(x: 9, y: -3)
                        .opacity(shouldDisplayUnreadBadgeForMeetings ? 1 : 0)
                })
                Divider()
                    .frame(maxHeight: 1)
                    .background(chatViewMode == .meetings ? TokenColors.Button.brand.swiftUI : TokenColors.Icon.secondary.swiftUI)
                    .opacity(chatViewMode == .meetings ? 1 : 0)
            }
        }
        .frame(maxHeight: 44)
        .background(colorScheme == .dark ? MEGAAppColor.Black._161616.color : MEGAAppColor.White._F7F7F7.color)
    }
}
