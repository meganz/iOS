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
                .foregroundColor(.white)
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
        if isReconnecting {
            return Color(.systemOrange)
        } else {
            return colorScheme == .dark ? Color(UIColor.mnz_green00C29A()) : Color(UIColor.mnz_green00A886())
        }
    }
}
