
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
            Spacer()
            Text(dateFormatted)
                .foregroundColor(datePickerVisible ? Color(UIColor.mnz_green00A886()) : (colorScheme == .dark ? Color.white : Color(UIColor.mnz_gray3C3C43()).opacity(0.6)))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
        .padding(.horizontal)
        
        if datePickerVisible {
            Divider()
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
            .background(colorScheme == .dark ? Color(Colors.General.Black._1c1c1e.name) : .white)
        }
    }
}
