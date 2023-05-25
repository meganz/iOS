import SwiftUI

struct ScheduleMeetingCreationRecurrenceOptionsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject var viewModel: ScheduleMeetingCreationRecurrenceOptionsViewModel

    var body: some View {
        List {
            Section {
                ForEach(viewModel.recurrenceOptions(forSection: 0)) { option in
                    RecurrenceOptionView(name: option.localizedString, isSelected: viewModel.selectedOption == option)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.selectedOption = option
                        }
                }
            }
        }
        .listStyle(.grouped)
        .navigationTitle(Strings.Localizable.Meetings.ScheduleMeeting.Create.RecurrenceOptionScreen.navigationTitle)
    }
}

private struct RecurrenceOptionView: View {
    let name: String
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Text(name)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(Color(Colors.Chat.Meeting.frequencySelectionTickMark.color))
                    .font(.system(.footnote).bold())
            }
        }
    }
}
