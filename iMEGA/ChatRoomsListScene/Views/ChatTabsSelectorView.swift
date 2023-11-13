import MEGAL10n
import SwiftUI

struct ChatTabsSelectorView: View {
    @Environment(\.colorScheme) private var colorScheme
    var chatViewMode: ChatViewMode
    var action: (ChatViewMode) -> Void
    
    private let defaultTabFont = Font.system(.subheadline, design: .default).weight(.regular)
    private let selectedTabFont = Font.system(.subheadline, design: .default).weight(.medium)
    
    var body: some View {
        HStack(spacing: 0) {
            VStack {
                Spacer()
                Button(action: {
                    action(.chats)
                }, label: {
                    Text(Strings.Localizable.Chat.Selector.chat)
                        .font(chatViewMode == .chats ? selectedTabFont : defaultTabFont)
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
                        .font(chatViewMode == .meetings ? selectedTabFont : defaultTabFont)
                        .foregroundColor(Color(chatViewMode == .meetings ? Colors.Chat.Tabs.chatTabSelectedText.color : Colors.Chat.Tabs.chatTabNormalText.color))
                })
                Divider()
                    .frame(maxHeight: 1)
                    .background(Color(chatViewMode == .meetings ? Colors.Chat.Tabs.chatTabSelectedBackground.color : Colors.Chat.Tabs.chatTabNormalBackground.color))
            }
        }
        .frame(maxHeight: 44)
        .background(colorScheme == .dark ?  Color(Colors.General.Black._161616.name) : Color(.whiteF7F7F7))
    }
}
