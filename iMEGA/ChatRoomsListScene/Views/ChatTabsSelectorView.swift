import MEGAL10n
import SwiftUI

struct ChatTabsSelectorView: View {
    @Environment(\.colorScheme) private var colorScheme
    var chatViewMode: ChatViewMode
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
                        .foregroundColor(Color(chatViewMode == .chats ? Colors.Chat.Tabs.chatTabSelectedText.color : Colors.Chat.Tabs.chatTabNormalText.color))
                })
                Divider()
                    .frame(maxHeight: 1)
                    .background(Color(chatViewMode == .chats ? Colors.Chat.Tabs.chatTabSelectedBackground.color : Colors.Chat.Tabs.chatTabNormalBackground.color))
            }
            
            VStack {
                Spacer()
                Button(action: {
                    action(.meetings)
                }, label: {
                    Text(Strings.Localizable.Chat.Selector.meeting)
                        .font(Font.system(.subheadline, design: .default).weight(.medium))
                        .foregroundColor(Color(chatViewMode == .meetings ? Colors.Chat.Tabs.chatTabSelectedText.color : Colors.Chat.Tabs.chatTabNormalText.color))
                })
                Divider()
                    .frame(maxHeight: 1)
                    .background(Color(chatViewMode == .meetings ? Colors.Chat.Tabs.chatTabSelectedBackground.color : Colors.Chat.Tabs.chatTabNormalBackground.color))
            }
        }
        .frame(maxHeight: 44)
        .background(colorScheme == .dark ?  Color(UIColor.black161616) : Color(.whiteF7F7F7))
    }
}
