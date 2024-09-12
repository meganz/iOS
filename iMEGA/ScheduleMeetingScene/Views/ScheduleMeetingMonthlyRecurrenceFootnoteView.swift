import MEGADesignToken
import SwiftUI

struct ScheduleMeetingMonthlyRecurrenceFootnoteView: View {
    @Environment(\.colorScheme) private var colorScheme
    let text: String
    
    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 6)
            .padding(.bottom, 20)
            .background(TokenColors.Background.page.swiftUI)
    }
}
