import MEGADesignToken
import SwiftUI

struct ChatRoomActiveCallView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @ObservedObject var viewModel: ActiveCallViewModel
    
    var body: some View {
        HStack {
            Spacer()
            Text(viewModel.message)
                .font(.caption)
                .bold()
                .foregroundColor(TokenColors.Text.inverseAccent.swiftUI)
            Image(uiImage: viewModel.muted)
            Image(uiImage: viewModel.video)
            Spacer()
        }
        .padding(8)
        .frame(maxHeight: 44)
        .background(backgroundColor(isReconnecting: viewModel.isReconnecting))
        .onTapGesture {
            viewModel.activeCallViewTapped()
        }
    }
    
    func backgroundColor(isReconnecting: Bool) -> Color {
        isReconnecting ? Color(.systemOrange) : TokenColors.Button.primary.swiftUI
    }
}
