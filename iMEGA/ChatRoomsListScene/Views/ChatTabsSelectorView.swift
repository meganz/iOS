
import SwiftUI

struct ChatTabsSelectorView: View  {
    @Environment(\.colorScheme) private var colorScheme
    var chatMode: ChatMode
    var action: (ChatMode) -> Void
    
    var body: some View {
        HStack (spacing: 0) {
            VStack {
                Spacer()
                Button(action: {
                    action(.chats)
                }, label: {
                    Text(Strings.Localizable.Chat.Selector.chat)
                        .font(.subheadline)
                        .foregroundColor(Color(chatMode == .chats ? Colors.Chat.Tabs.chatTabSelectedText.color : Colors.Chat.Tabs.chatTabNormalText.color))
                })
                Divider()
                    .frame(maxHeight: 1)
                    .background(Color(chatMode == .chats ? Colors.Chat.Tabs.chatTabSelectedBackground.color : Colors.Chat.Tabs.chatTabNormalBackground.color))
            }
            
            VStack {
                Spacer()
                Button(action: {
                    action(.meetings)
                }, label: {
                    Text(Strings.Localizable.Chat.Selector.meeting)
                        .font(.subheadline)
                        .foregroundColor(Color(chatMode == .meetings ? Colors.Chat.Tabs.chatTabSelectedText.color : Colors.Chat.Tabs.chatTabNormalText.color))
                })
                Divider()
                    .frame(maxHeight: 1)
                    .background(Color(chatMode == .meetings ? Colors.Chat.Tabs.chatTabSelectedBackground.color : Colors.Chat.Tabs.chatTabNormalBackground.color))
            }
        }
        .frame(maxHeight: 44)
        .background(colorScheme == .dark ?  Color(Colors.General.Black._161616.name) : Color(Colors.General.White.f7F7F7.name))
    }
}

