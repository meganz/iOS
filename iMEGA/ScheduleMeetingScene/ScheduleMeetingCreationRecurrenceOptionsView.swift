import SwiftUI

struct ScheduleMeetingCreationRecurrenceOptionsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject var viewModel: ScheduleMeetingCreationRecurrenceOptionsViewModel

    var body: some View {
        List {
            nonCustomizedOptionsSection()
            customizedOptionSection()
        }
        .listStyle(.grouped)
        .navigationTitle(Strings.Localizable.Meetings.ScheduleMeeting.Create.RecurrenceOptionScreen.navigationTitle)
        .onAppear {
            viewModel.updateUI()
        }
    }
    
    private func nonCustomizedOptionsSection() -> some View {
        Section {
            ForEach(viewModel.nonCustomizedOptions()) { option in
                RecurrenceOptionView(name: option.localizedString, isSelected: viewModel.selectedOption == option) {
                    viewModel.updateSelection(withRecurrenceOption: option)
                    viewModel.dismiss()
                }
            }
        }
    }
    
    private func customizedOptionSection() -> some View {
        Section {
            let optionName = viewModel.customizedOption().localizedString
            if viewModel.selectedOption == .custom {
                RecurrenceOptionView(name: optionName, isSelected: true) {
                    viewModel.navigateToCustomOptionsScreen()
                }
            } else {
                DetailDisclosureView(text: optionName, requiresPadding: false) {
                    viewModel.navigateToCustomOptionsScreen()
                }
            }
        } footer: {
            if let footerNote = viewModel.customOptionFooterNote() {
                Text(footerNote)
            }
        }
    }
}
