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
                    datePickerVisible ? 
                    (isDesignTokenEnabled ?
                     TokenColors.Support.success.swiftUI : Color(UIColor.mnz_green00A886()))
                    : (isDesignTokenEnabled ? TokenColors.Text.secondary.swiftUI : (colorScheme == .dark ? MEGAAppColor.White._FFFFFF.color : MEGAAppColor.Gray._3C3C43.color.opacity(0.6))
                ))
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
            .background(isDesignTokenEnabled
                        ? TokenColors.Background.page.swiftUI
                        : colorScheme == .dark ? MEGAAppColor.Black._1C1C1E.color : MEGAAppColor.White._FFFFFF.color)
        }
    }
}
