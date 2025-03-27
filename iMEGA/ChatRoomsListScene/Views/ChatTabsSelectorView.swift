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
            VStack(spacing: 0) {
                Button(action: {
                    action(.chats)
                }, label: {
                    Text(Strings.Localizable.Chat.Selector.chat)
                        .font(Font.system(.subheadline, design: .default).weight(.medium))
                        .foregroundColor(chatViewMode == .chats ? TokenColors.Button.brand.swiftUI : TokenColors.Icon.secondary.swiftUI)
                        .frame(minHeight: 40)
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
                    .background(TokenColors.Button.brand.swiftUI)
                    .opacity(chatViewMode == .chats ? 1 : 0)
            }
            
            VStack(spacing: 0) {
                Button(action: {
                    action(.meetings)
                }, label: {
                    Text(Strings.Localizable.Chat.Selector.meeting)
                        .font(Font.system(.subheadline, design: .default).weight(.medium))
                        .foregroundColor(chatViewMode == .meetings ? TokenColors.Button.brand.swiftUI : TokenColors.Icon.secondary.swiftUI)
                        .frame(minHeight: 40)
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
                    .background(TokenColors.Button.brand.swiftUI)
                    .opacity(chatViewMode == .meetings ? 1 : 0)
            }
        }
        .background(TokenColors.Background.surface1.swiftUI)
    }
}
