import SwiftUI

struct WaitingRoomJoinPanelView: View {
    let tapJoinAction: () -> Void
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    
    var body: some View {
        VStack {
            HStack {
                TextField(Strings.Localizable.Meetings.WaitingRoom.Guest.firstName, text: $firstName)
                    .font(.body)
                    .frame(width: 85)
                Spacer()
                    .frame(width: 20)
                TextField(Strings.Localizable.Meetings.WaitingRoom.Guest.lastName, text: $lastName)
                    .font(.body)
                    .frame(width: 85)
            }
            .padding()
            
            Button {
                tapJoinAction()
            } label: {
                Text(Strings.Localizable.Meetings.WaitingRoom.Guest.join)
                    .foregroundColor(.white)
                    .font(.system(size: 17, weight: .bold))
                    .frame(width: 288, height: 50)
                    .background(Color(Colors.General.Green._00C29A.name))
            }
            .cornerRadius(8)
            .disabled(firstName.isEmpty || lastName.isEmpty)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(Colors.General.Black._1c1c1e.name))
    }
}

struct WaitingRoomJoinPanelView_Previews: PreviewProvider {
    static var previews: some View {
        WaitingRoomJoinPanelView(tapJoinAction: {})
            .preferredColorScheme(.dark)
            .previewLayout(.sizeThatFits)
    }
}
