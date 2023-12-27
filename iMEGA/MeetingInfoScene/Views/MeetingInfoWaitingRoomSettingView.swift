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
            .background(colorScheme == .dark ? MEGAAppColor.Black._1C1C1E.color : MEGAAppColor.White._FFFFFF.color)
            
            Text(Strings.Localizable.Meetings.ScheduleMeeting.WaitingRoom.description)
                .font(.footnote)
                .foregroundColor(colorScheme == .dark ? MEGAAppColor.White._FFFFFF.color.opacity(0.6) : Color(MEGAAppColor.Gray._3C3C43.uiColor).opacity(0.6))
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
                    .background(colorScheme == .dark ? MEGAAppColor.Black._000000.color : MEGAAppColor.White._F7F7F7.color)
                MeetingInfoWaitingRoomSettingView(isWaitingRoomOn: .constant(true), shouldAllowEditingWaitingRoom: false)
                    .background(colorScheme == .dark ? MEGAAppColor.Black._000000.color : MEGAAppColor.White._F7F7F7.color)
            }
        }
    }
    
    static var previews: some View {
        Shim()
            .previewLayout(.sizeThatFits)
    }
}
