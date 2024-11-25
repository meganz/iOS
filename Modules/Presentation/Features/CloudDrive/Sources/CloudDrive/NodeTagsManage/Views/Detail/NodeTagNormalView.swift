import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct NodeTagNormalView: View {
    let tag: String

    var body: some View {
        PillView(
            viewModel: PillViewModel(
                title: tag,
                icon: .none,
                foreground: TokenColors.Text.primary.swiftUI,
                background: TokenColors.Button.secondary.swiftUI,
                font: .subheadline
            )
        )
    }
}
