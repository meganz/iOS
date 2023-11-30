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
                .foregroundColor(Color.chatMeetingFrequencySelectionTickMark)
                .font(.system(.footnote).bold())
                .opacity(isSelected ? 1 : 0)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }
}
