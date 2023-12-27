import MEGAL10n
import SwiftUI

struct ScheduleMeetingCreationWaitingRoomView: View {
    @Binding var waitingRoomEnabled: Bool
    let shouldAllowEditingWaitingRoom: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack {
            Divider()
            
            Toggle(isOn: $waitingRoomEnabled) {
                Text(Strings.Localizable.Meetings.ScheduleMeeting.waitingRoom)
                    .opacity(shouldAllowEditingWaitingRoom ? 1.0 : 0.3)
            }
            .toggleStyle(SwitchToggleStyle(tint: Color(UIColor.mnz_green00A886())))
            .padding(.horizontal)
            .disabled(!shouldAllowEditingWaitingRoom)
            
            Divider()
        }
        .background(colorScheme == .dark ? MEGAAppColor.Black._1C1C1E.color : MEGAAppColor.White._FFFFFF.color)
        
        ScheduleMeetingCreationFootnoteView(title: Strings.Localizable.Meetings.ScheduleMeeting.WaitingRoom.description)
            .padding(.bottom)
    }
}

struct ScheduleMeetingCreationWaitingRoomView_Previews: PreviewProvider {
    
    private struct Shim: View {
        @Environment(\.colorScheme) private var colorScheme
        
        var body: some View {
            VStack {
                ScheduleMeetingCreationWaitingRoomView(waitingRoomEnabled: .constant(true), shouldAllowEditingWaitingRoom: true)
                    .background(colorScheme == .dark ? MEGAAppColor.Black._000000.color : MEGAAppColor.White._F7F7F7.color)
            }
        }
    }
    
    static var previews: some View {
        Shim()
            .previewLayout(.sizeThatFits)
    }
}
