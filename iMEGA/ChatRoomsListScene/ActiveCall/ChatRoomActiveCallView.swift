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
                .foregroundColor(MEGAAppColor.White._FFFFFF.color)
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
            return colorScheme == .dark ? MEGAAppColor.Green._00C29A.color : MEGAAppColor.Green._00A886.color
        }
    }
}
