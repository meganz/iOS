import MEGADesignToken
import MEGAL10n
import SwiftUI

struct ScheduleMeetingCreationWaitingRoomView: View {
    @Binding var waitingRoomEnabled: Bool
    let shouldAllowEditingWaitingRoom: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .foregroundStyle(TokenColors.Border.subtle.swiftUI)
            
            Toggle(isOn: $waitingRoomEnabled) {
                Text(Strings.Localizable.Meetings.ScheduleMeeting.waitingRoom)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                    .opacity(shouldAllowEditingWaitingRoom ? 1.0 : 0.3)
            }
            .frame(minHeight: 44)
            .toggleStyle(SwitchToggleStyle(tint: isDesignTokenEnabled
                                           ? TokenColors.Support.success.swiftUI
                                           : Color(UIColor.mnz_green00A886())))
            .padding(.horizontal)
            .disabled(!shouldAllowEditingWaitingRoom)
            
            Divider()
                .foregroundStyle(TokenColors.Border.subtle.swiftUI)
        }
        .background(isDesignTokenEnabled
                    ? TokenColors.Background.page.swiftUI
                    : colorScheme == .dark ? MEGAAppColor.Black._1C1C1E.color : MEGAAppColor.White._FFFFFF.color)
        
        ScheduleMeetingCreationFootnoteView(title: Strings.Localizable.Meetings.ScheduleMeeting.WaitingRoom.description)
            .padding(.bottom)
    }
}

#Preview() {
    struct Shim: View {
        @Environment(\.colorScheme) private var colorScheme
        
        var body: some View {
            VStack {
                ScheduleMeetingCreationWaitingRoomView(waitingRoomEnabled: .constant(true), shouldAllowEditingWaitingRoom: true)
                    .background(colorScheme == .dark ? MEGAAppColor.Black._000000.color : MEGAAppColor.White._F7F7F7.color)
            }
        }
    }
    
    return Shim()
        .previewLayout(.sizeThatFits)
}
