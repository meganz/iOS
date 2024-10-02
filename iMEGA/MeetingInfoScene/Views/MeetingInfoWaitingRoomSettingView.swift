import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct MeetingInfoWaitingRoomSettingView: View {
    @Binding var isWaitingRoomOn: Bool
    let shouldAllowEditingWaitingRoom: Bool
    
    var body: some View {
        VStack {
            ToggleView(
                image: .enableWaitingRoom,
                text: Strings.Localizable.Meetings.ScheduleMeeting.waitingRoom,
                enabled: shouldAllowEditingWaitingRoom,
                isOn: $isWaitingRoomOn)
            .background()
            
            Text(Strings.Localizable.Meetings.ScheduleMeeting.WaitingRoom.description)
                .font(.footnote)
                .foregroundColor(TokenColors.Text.secondary.swiftUI)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.bottom, 5)
        }
    }
}

@available(iOS 17.0, *)
#Preview(traits: .sizeThatFitsLayout) {
    struct Shim: View {
        @Environment(\.colorScheme) private var colorScheme
        
        var body: some View {
            VStack {
                MeetingInfoWaitingRoomSettingView(isWaitingRoomOn: .constant(true), shouldAllowEditingWaitingRoom: true)
                    .background()
                MeetingInfoWaitingRoomSettingView(isWaitingRoomOn: .constant(true), shouldAllowEditingWaitingRoom: false)
                    .background()
            }
        }
    }
    
    return Shim()
}
