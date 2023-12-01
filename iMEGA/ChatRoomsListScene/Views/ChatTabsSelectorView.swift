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
                        .foregroundColor(Color(chatViewMode == .chats ? UIColor.chatTabSelectedText : UIColor.chatTabNormalText))
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
                Divider()
                    .frame(maxHeight: 1)
                    .background(Color(chatViewMode == .meetings ? UIColor.chatTabSelectedBackground : UIColor.chatTabNormalBackground))
            }
        }
        .frame(maxHeight: 44)
        .background(colorScheme == .dark ?  Color(UIColor.black161616) : Color(.whiteF7F7F7))
    }
}
