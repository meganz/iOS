import MEGADesignToken
import SwiftUI

struct ScheduleMeetingCreationMonthlyDatePickerView: View {
    let days: [String]
    let rows: Int
    let columns: Int
    let columnPadding: Int
    let allowsMultipleSelection: Bool
    @Binding var selectedDays: Set<String>
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<rows, id: \.self) { row in
                let displayDays = daysToDisplay(forRow: row)
                let leadingColumnPaddingCount = min(max(columnPadding - (row * columns), 0), columns)
                ScheduleMeetingCreationMonthlyDatePickerRowView(
                    days: displayDays,
                    leadingColumnPaddingCount: leadingColumnPaddingCount,
                    trailingColumnPaddingCount: columns - displayDays.count - leadingColumnPaddingCount,
                    allowsMultipleSelection: allowsMultipleSelection,
                    selectedDays: $selectedDays
                )
            }
        }
    }
    
    private func daysToDisplay(forRow row: Int) -> [String] {
        let factor = (row * columns)
        let startIndex = max(factor - columnPadding, 0)
        guard startIndex < days.count else { return [] }
        let endIndex = max(min(factor + columns - columnPadding, days.count), 0)
        return Array(days[startIndex..<endIndex])
    }
}

private struct ScheduleMeetingCreationMonthlyDatePickerRowView: View {
    let days: [String]
    let leadingColumnPaddingCount: Int
    let trailingColumnPaddingCount: Int
    let allowsMultipleSelection: Bool
    @Binding var selectedDays: Set<String>
    
    var body: some View {
        HStack {
            Group {
                view(forPaddingCount: leadingColumnPaddingCount)
                
                ForEach(days, id: \.self) { day in
                    ScheduleMeetingCreationMonthlyDatePickerTileView(
                        day: day,
                        selected: selectedDays.contains(day)
                    )
                    .onTapGesture {
                        withAnimation {
                            if allowsMultipleSelection {
                                toggleSelection(forDay: day)
                            } else {
                                singleSelect(day: day)
                            }
                        }
                    }
                }
                
                view(forPaddingCount: trailingColumnPaddingCount)
            }
            .frame(height: 48)
            .frame(maxWidth: .infinity)
        }
    }
    
    private func view(forPaddingCount paddingCount: Int) -> some View {
        ForEach(0..<paddingCount, id: \.self) { _ in
            Text("")
        }
    }
    
    private func toggleSelection(forDay day: String) {
        if !selectedDays.contains(day) {
            selectedDays.insert(day)
        } else if selectedDays.count > 1 {
            selectedDays.remove(day)
        }
    }
    
    private func singleSelect(day: String) {
        selectedDays.removeAll()
        selectedDays.insert(day)
    }
}

private struct ScheduleMeetingCreationMonthlyDatePickerTileView: View {
    @Environment(\.colorScheme) var colorScheme
    let day: String
    let selected: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(TokenColors.Support.success.swiftUI)
                .opacity(selected ? 1.0 : 0.0)
            Text(day)
                .font(.title3)
                .foregroundStyle(
                    (colorScheme == .light && selected) ?
                    TokenColors.Background.page.swiftUI : TokenColors.Text.primary.swiftUI
                )
        }
    }
}
