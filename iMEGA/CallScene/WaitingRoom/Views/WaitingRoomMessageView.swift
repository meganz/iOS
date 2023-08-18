import SwiftUI

struct WaitingRoomMessageView: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.subheadline)
            .foregroundColor(.black)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.white)
            .cornerRadius(44)
    }
}

struct WaitingRoomMessageView_Previews: PreviewProvider {
    static var previews: some View {
        WaitingRoomMessageView(title: "Wait for host to let you in")
            .padding(20)
            .background(Color.black)
            .previewLayout(.sizeThatFits)
    }
}
