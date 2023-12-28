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
                        .foregroundColor(chatViewMode == .chats ? MEGAAppColor.Chat.chatTabSelectedText.color : MEGAAppColor.Chat.chatTabNormalText.color)
                    
                })
                .overlay(alignment: .trailing, content: {
                    Circle()
                        .fill(MEGAAppColor.Red._FF0000.color)
                        .frame(width: 5, height: 5)
                        .offset(x: 9, y: -3)
                        .opacity(shouldDisplayUnreadBadgeForChats ? 1 : 0)
                })
                Divider()
                    .frame(maxHeight: 1)
                    .background(chatViewMode == .chats ? MEGAAppColor.Chat.chatTabSelectedBackground.color : MEGAAppColor.Chat.chatTabNormalBackground.color)
            }
            
            VStack {
                Spacer()
                Button(action: {
                    action(.meetings)
                }, label: {
                    Text(Strings.Localizable.Chat.Selector.meeting)
                        .font(Font.system(.subheadline, design: .default).weight(.medium))
                        .foregroundColor(chatViewMode == .meetings ? MEGAAppColor.Chat.chatTabSelectedText.color : MEGAAppColor.Chat.chatTabNormalText.color)
                })
                .overlay(alignment: .trailing, content: {
                    Circle()
                        .fill(MEGAAppColor.Red._FF0000.color)
                        .frame(width: 5, height: 5)
                        .offset(x: 9, y: -3)
                        .opacity(shouldDisplayUnreadBadgeForMeetings ? 1 : 0)
                })
                Divider()
                    .frame(maxHeight: 1)
                    .background(chatViewMode == .meetings ? MEGAAppColor.Chat.chatTabSelectedBackground.color : MEGAAppColor.Chat.chatTabNormalBackground.color)
            }
        }
        .frame(maxHeight: 44)
        .background(colorScheme == .dark ? MEGAAppColor.Black._161616.color : MEGAAppColor.White._F7F7F7.color)
    }
}
