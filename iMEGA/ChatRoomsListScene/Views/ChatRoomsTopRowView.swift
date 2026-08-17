import MEGADesignToken
import SwiftUI

struct ChatRoomsTopRowView: View {
    @Environment(\.layoutDirection) var layoutDirection
    /// Set by `.disabled(_:)` further up, for rows whose action needs a connection.
    @Environment(\.isEnabled) var isEnabled

    let state: ChatRoomsTopRowViewState
    private let disclosureIndicator = "chevron.right"

    var body: some View {
        HStack {
            Image(uiImage: state.image)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .opacity(isEnabled ? 1 : 0.5)

            Text(state.description)
                .font(.subheadline)
                .foregroundStyle(textStyle)

            Spacer()

            if let rightDetail = state.rightDetail {
                Text(rightDetail)
                    .font(.body)
                    .foregroundStyle(textStyle)
            }

            Image(systemName: disclosureIndicator)
                .foregroundColor(isEnabled ? TokenColors.Icon.secondary.swiftUI : TokenColors.Icon.disabled.swiftUI)
                .flipsForRightToLeftLayoutDirection(layoutDirection == .rightToLeft)
        }
        .contentShape(Rectangle())
    }

    /// `.foreground` keeps whatever the row inherited, so an enabled row looks exactly as before.
    private var textStyle: AnyShapeStyle {
        isEnabled ? AnyShapeStyle(.foreground) : AnyShapeStyle(TokenColors.Text.disabled.swiftUI)
    }
}
