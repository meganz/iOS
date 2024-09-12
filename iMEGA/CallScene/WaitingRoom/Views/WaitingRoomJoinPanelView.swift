import MEGADesignToken
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
                    .foregroundColor(
                        disableJoinButton ?
                            TokenColors.Text.disabled.swiftUI :
                            TokenColors.Text.inverse.swiftUI
                    )
                    .font(.system(size: 17, weight: .bold))
                    .frame(width: 288, height: 50)
                    .background(
                        disableJoinButton ?
                            TokenColors.Button.disabled.swiftUI :
                            TokenColors.Button.primary.swiftUI
                    )
            }
            .cornerRadius(8)
            .disabled(disableJoinButton)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TokenColors.Background.surface1.swiftUI)
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

#Preview {
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
    .background(Color(.black000000))
}
