import MEGADesignToken
import SwiftUI

struct DatePickerView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let title: String
    @Binding var dateFormatted: String
    @Binding var datePickerVisible: Bool
    @Binding var date: Date
    let dateRange: PartialRangeFrom<Date>
    let action: (() -> Void)
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
            Spacer()
            Text(dateFormatted)
                .foregroundStyle(
                    datePickerVisible ? TokenColors.Support.success.swiftUI
                    : TokenColors.Text.secondary.swiftUI
                )
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
        .padding(.horizontal)
        
        if datePickerVisible {
            Divider()
                .foregroundStyle(TokenColors.Border.subtle.swiftUI)
                .padding(.leading)
            DatePicker(
                "",
                selection: $date,
                in: dateRange,
                displayedComponents: [.date, .hourAndMinute]
            )
            .labelsHidden()
            .datePickerStyle(.wheel)
            .onAppear {
                UIDatePicker.appearance().minuteInterval = 5
            }
            .background(TokenColors.Background.page.swiftUI)
        }
    }
}
