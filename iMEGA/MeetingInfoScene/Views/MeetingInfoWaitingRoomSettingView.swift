import MEGAL10n
import SwiftUI

struct MeetingInfoWaitingRoomSettingView: View {
    @Binding var isWaitingRoomOn: Bool
    let shouldAllowEditingWaitingRoom: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack {
            ToggleView(
                image: .enableWaitingRoom,
                text: Strings.Localizable.Meetings.ScheduleMeeting.waitingRoom,
                enabled: shouldAllowEditingWaitingRoom,
                isOn: $isWaitingRoomOn)
            .background(colorScheme == .dark ? Color(.black1C1C1E) : .white)
            
            Text(Strings.Localizable.Meetings.ScheduleMeeting.WaitingRoom.description)
                .font(.footnote)
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.6) : Color(UIColor.gray3C3C43).opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.bottom, 5)
        }
    }
}

struct MeetingInfoWaitingRoomSettingView_Previews: PreviewProvider {
    
    private struct Shim: View {
        @Environment(\.colorScheme) private var colorScheme
        
        var body: some View {
            VStack {
                MeetingInfoWaitingRoomSettingView(isWaitingRoomOn: .constant(true), shouldAllowEditingWaitingRoom: true)
                    .background(colorScheme == .dark ? .black : Color(.whiteF7F7F7))
                MeetingInfoWaitingRoomSettingView(isWaitingRoomOn: .constant(true), shouldAllowEditingWaitingRoom: false)
                    .background(colorScheme == .dark ? .black : Color(.whiteF7F7F7))
            }
        }
    }
    
    static var previews: some View {
        Shim()
            .previewLayout(.sizeThatFits)
    }
}
