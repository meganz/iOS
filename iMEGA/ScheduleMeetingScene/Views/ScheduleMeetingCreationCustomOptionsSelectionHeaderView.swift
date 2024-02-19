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
                .foregroundStyle(
                    colorScheme == .dark
                    ? darkThemeForegroundTextColor()
                    : lightThemeForegroundTextColor()
                )
        }
        .contentShape(Rectangle())
        .onTapGesture {
            tapAction()
        }
    }
    
    private func lightThemeForegroundTextColor() -> Color {
        isExpanded
        ? (isDesignTokenEnabled ? TokenColors.Support.success.swiftUI : Color(UIColor.mnz_green00A886()))
        : (isDesignTokenEnabled ? TokenColors.Text.secondary.swiftUI : MEGAAppColor.Gray._3C3C43.color)
    }
    
    private func darkThemeForegroundTextColor() -> Color {
        isExpanded
        ? (isDesignTokenEnabled ? TokenColors.Support.success.swiftUI : MEGAAppColor.Green._00C29A.color)
        : (isDesignTokenEnabled ? TokenColors.Text.secondary.swiftUI : MEGAAppColor.White._FFFFFF.color.opacity(0.6))
    }
}
