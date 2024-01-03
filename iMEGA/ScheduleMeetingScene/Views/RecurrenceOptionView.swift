import SwiftUI

struct RecurrenceOptionView: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            Text(name)
            Spacer()
            Image(systemName: "checkmark")
                .foregroundColor(MEGAAppColor.Chat.chatMeetingFrequencySelectionTickMark.color)
                .font(.system(.footnote).bold())
                .opacity(isSelected ? 1 : 0)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }
}
