import MEGADesignToken
import MEGAL10n
import SwiftUI

struct ScheduleMeetingCreationCustomOptionsView: View {
    @StateObject var viewModel: ScheduleMeetingCreationCustomOptionsViewModel
    
    var body: some View {
        List {
            Section {
                ScheduleMeetingCreationCustomOptionsFrequencyView(viewModel: viewModel)
                ScheduleMeetingCreationCustomOptionsRepetitionRulesView(viewModel: viewModel)
            } footer: {
                Text(viewModel.intervalFooterNote)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
            }
            
            let monthlyOptionsViewModel = viewModel.monthlyOptionsViewModel
            
            Section {
                if let monthlyOptionsViewModel {
                    ScheduleMeetingCreationMonthlyCustomOptionsView(viewModel: monthlyOptionsViewModel)
                } else if let weeklyOptionsViewModel = viewModel.weeklyOptionsViewModel {
                    ScheduleMeetingCreationWeeklyCustomOptionsView(viewModel: weeklyOptionsViewModel)
                }
            } footer: {
                Text(monthlyOptionsViewModel?.calendarFooterNote() ?? "")
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
            }
        }
        .listStyle(.grouped)
        .navigationTitle(Strings.Localizable.Meetings.ScheduleMeeting.Create.RecurrenceOptionScreen.custom)
    }
}
