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
                        .foregroundColor(Color(chatViewMode == .chats ? UIColor.chatTabSelectedText : UIColor.chatTabNormalText))
                    
                })
                .overlay(alignment: .trailing, content: {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 5, height: 5)
                        .offset(x: 9, y: -3)
                        .opacity(shouldDisplayUnreadBadgeForChats ? 1 : 0)
                })
                Divider()
                    .frame(maxHeight: 1)
                    .background(Color(chatViewMode == .chats ? UIColor.chatTabSelectedBackground : UIColor.chatTabNormalBackground))
            }
            
            VStack {
                Spacer()
                Button(action: {
                    action(.meetings)
                }, label: {
                    Text(Strings.Localizable.Chat.Selector.meeting)
                        .font(Font.system(.subheadline, design: .default).weight(.medium))
                        .foregroundColor(Color(chatViewMode == .meetings ? UIColor.chatTabSelectedText : UIColor.chatTabNormalText))
                })
                .overlay(alignment: .trailing, content: {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 5, height: 5)
                        .offset(x: 9, y: -3)
                        .opacity(shouldDisplayUnreadBadgeForMeetings ? 1 : 0)
                })
                Divider()
                    .frame(maxHeight: 1)
                    .background(Color(chatViewMode == .meetings ? UIColor.chatTabSelectedBackground : UIColor.chatTabNormalBackground))
            }
        }
        .frame(maxHeight: 44)
        .background(colorScheme == .dark ?  Color(MEGAAppColor.Black._161616.uiColor) : Color(.whiteF7F7F7))
    }
}
