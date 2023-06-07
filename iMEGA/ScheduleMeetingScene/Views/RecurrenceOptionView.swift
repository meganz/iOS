import SwiftUI

struct RecurrenceOptionView: View {
    let name: String
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Text(name)
            Spacer()
            Image(systemName: "checkmark")
                .foregroundColor(Color(Colors.Chat.Meeting.frequencySelectionTickMark.color))
                .font(.system(.footnote).bold())
                .opacity(isSelected ? 1 : 0)
        }
    }
}
