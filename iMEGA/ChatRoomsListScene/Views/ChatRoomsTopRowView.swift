import MEGADesignToken
import SwiftUI

struct ChatRoomsTopRowView: View {
    @Environment(\.layoutDirection) var layoutDirection

    let state: ChatRoomsTopRowViewState
    private let disclosureIndicator = "chevron.right"
    
    var body: some View {
        HStack {
            Image(uiImage: state.image)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
            
            Text(state.description)
                .font(.subheadline)
            
            Spacer()
            
            if let rightDetail = state.rightDetail {
                Text(rightDetail)
                    .font(.body)
            }
            
            Image(systemName: disclosureIndicator)
                .foregroundColor(TokenColors.Icon.secondary.swiftUI)
                .flipsForRightToLeftLayoutDirection(layoutDirection == .rightToLeft)
        }
        .contentShape(Rectangle())
    }
}
