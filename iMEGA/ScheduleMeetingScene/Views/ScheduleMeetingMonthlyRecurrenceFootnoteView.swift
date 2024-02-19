import MEGADesignToken
import SwiftUI

struct ScheduleMeetingMonthlyRecurrenceFootnoteView: View {
    @Environment(\.colorScheme) private var colorScheme
    let text: String
    
    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(isDesignTokenEnabled
                             ? TokenColors.Text.secondary.swiftUI
                             : colorScheme == .dark ? MEGAAppColor.White._FFFFFF.color.opacity(0.6) : MEGAAppColor.Gray._3C3C43.color.opacity(0.6))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 6)
            .padding(.bottom, 20)
            .background(isDesignTokenEnabled
                        ? TokenColors.Background.page.swiftUI
                        : colorScheme == .dark ? MEGAAppColor.Black._000000.color : MEGAAppColor.White._F7F7F7.color)
    }
}
