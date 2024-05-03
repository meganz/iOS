import SwiftUI

struct WaitingRoomMessageView: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.subheadline)
            .foregroundColor(MEGAAppColor.Black._000000.color)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(MEGAAppColor.White._FFFFFF.color)
            .cornerRadius(44)
    }
}

#Preview {
    WaitingRoomMessageView(title: "Wait for host to let you in")
        .padding(20)
        .background(MEGAAppColor.Black._000000.color)
        .previewLayout(.sizeThatFits)
}
