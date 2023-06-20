import SwiftUI

struct ScheduleMeetingCreationCustomOptionsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject var viewModel: ScheduleMeetingCreationCustomOptionsViewModel
    
    var body: some View {
        List {
            Section {
                ScheduleMeetingCreationCustomOptionsFrequencyView(viewModel: viewModel)
                ScheduleMeetingCreationCustomOptionsRepetitionRulesView(viewModel: viewModel)
            } footer: {
                Text(viewModel.intervalFooterNote)
            }
            
            let monthlyOptionsViewModel = viewModel.monthlyOptionsViewModel
            
            Section {
                if let monthlyOptionsViewModel {
                    ScheduleMeetingCreationMonthlyCustomOptionsView(viewModel: monthlyOptionsViewModel)
                } else if let weeklyOptionsViewModel = viewModel.weeklyOptionsViewModel {
                    ScheduleMeetingCreationWeeklyCustomOptionsView(viewModel: weeklyOptionsViewModel)
                }
            } footer: {
                if let footerNote = monthlyOptionsViewModel?.calendarFooterNote() {
                    Text(footerNote)
                }
            }
        }
        .listStyle(.grouped)
        .navigationTitle(Strings.Localizable.Meetings.ScheduleMeeting.Create.RecurrenceOptionScreen.custom)
    }
}
