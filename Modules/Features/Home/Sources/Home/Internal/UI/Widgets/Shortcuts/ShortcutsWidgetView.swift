import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct ShortcutsWidgetView: View {
    let shortcutTapAction: (ShortcutType) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: TokenSpacing._3) {
                ForEach(ShortcutType.allCases) { chip in
                    Button {
                        shortcutTapAction(chip)
                    } label: {
                        PillView(viewModel: chip.pillViewModel)
                    }
                }
            }
            .padding(.leading, TokenSpacing._5)
        }
        .padding(.vertical, TokenSpacing._4)
    }
}

#Preview {
    ShortcutsWidgetView(shortcutTapAction: { _ in })
}
