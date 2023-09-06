import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct WaitingRoomJoinPanelView: View {
    let tapJoinAction: (String, String) -> Void
    let appearFocused: Bool
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    
    private var disableJoinButton: Bool {
        firstName.isEmpty || lastName.isEmpty
    }
    
    var body: some View {
        VStack {
            HStack {
                FocusableNameTextFieldView(
                    placeholder: Strings.Localizable.Meetings.WaitingRoom.Guest.firstName,
                    text: $firstName,
                    appearFocused: appearFocused
                )
                .frame(maxWidth: 120)
                
                FocusableNameTextFieldView(
                    placeholder: Strings.Localizable.Meetings.WaitingRoom.Guest.lastName,
                    text: $lastName
                )
                .frame(maxWidth: 120)
            }
            Button {
                tapJoinAction(firstName, lastName)
                hideKeyboard()
            } label: {
                Text(Strings.Localizable.Meetings.WaitingRoom.Guest.join)
                    .foregroundColor(.white)
                    .font(.system(size: 17, weight: .bold))
                    .frame(width: 288, height: 50)
                    .background(Color(Colors.General.Green._00C29A.name))
            }
            .cornerRadius(8)
            .disabled(disableJoinButton)
            .opacity(disableJoinButton ? 0.3 : 1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(Colors.General.Black._1c1c1e.name))
    }
    
    struct FocusableNameTextFieldView: View {
        let placeholder: String
        @Binding var text: String
        var appearFocused: Bool = false
        
        var body: some View {
            FocusableTextFieldView(
                placeholder: placeholder,
                text: $text,
                appearFocused: appearFocused
            )
            .font(.body)
            .padding()
        }
    }
}

struct WaitingRoomJoinPanelView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            ZStack {
                WaitingRoomJoinPanelView(tapJoinAction: {firstName, lastName in
                    MEGALogDebug("firstName: \(firstName), lastName: \(lastName)")
                }, appearFocused: false)
            }
            .frame(height: 142)
        }
        .preferredColorScheme(.dark)
        .background(Color.black)
    }
}
