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
            Spacer()
            Text(selectedText)
                .foregroundColor(
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
        ? Color(UIColor.mnz_green00A886())
        : MEGAAppColor.Gray._3C3C43.color
    }
    
    private func darkThemeForegroundTextColor() -> Color {
        isExpanded
        ? MEGAAppColor.Green._00C29A.color
        : MEGAAppColor.White._FFFFFF.color.opacity(0.6)
    }
}
