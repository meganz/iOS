import SwiftUI

struct ScheduleMeetingCreationWeeklyCustomOptionsView: View {
    @ObservedObject var viewModel: ScheduleMeetingCreationWeeklyCustomOptionsViewModel

    var body: some View {
        ForEach(viewModel.weekdaySymbols, id: \.self) { weekSymbol in
            ScheduleMeetingCreationOptionSelectionView(
                name: weekSymbol,
                isSelected: viewModel.selectedWeekDays?.contains(weekSymbol) ?? false
            ) {
                viewModel.toggleSelection(forWeekDay: weekSymbol)
            }
        }
    }
}
