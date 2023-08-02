import SwiftUI

struct MeetingInfoWaitingRoomSettingView: View {
    @Binding var isWaitingRoomOn: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack {
            ToggleView(
                image: Asset.Images.Meetings.Info.enableWaitingRoom.name,
                text: Strings.Localizable.Meetings.ScheduleMeeting.waitingRoom,
                isOn: $isWaitingRoomOn)
            .background(colorScheme == .dark ? Color(Colors.General.Black._1c1c1e.name) : .white)
            
            Text(Strings.Localizable.Meetings.ScheduleMeeting.WaitingRoom.description)
                .font(.footnote)
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.6) : Color(UIColor.mnz_gray3C3C43()).opacity(0.6))
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
                MeetingInfoWaitingRoomSettingView(isWaitingRoomOn: .constant(true))
                    .background(colorScheme == .dark ? .black : Color(Colors.General.White.f7F7F7.name))
            }
        }
    }
    
    static var previews: some View {
        Shim()
            .previewLayout(.sizeThatFits)
    }
}
