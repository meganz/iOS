import MEGADesignToken
import SwiftUI

struct ScheduleMeetingCreationCustomOptionsSelectionHeaderView: View {
    let title: String
    let selectedText: String
    let isExpanded: Bool
    let tapAction: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
            Spacer()
            Text(selectedText)
                .foregroundStyle(foregroundTextColor())
        }
        .contentShape(Rectangle())
        .onTapGesture {
            tapAction()
        }
    }
    
    private func foregroundTextColor() -> Color {
        isExpanded
        ? TokenColors.Support.success.swiftUI
        : TokenColors.Text.secondary.swiftUI
    }
}
