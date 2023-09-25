import SwiftUI

struct WaitingRoomControlsView: View {
    @Binding var isVideoEnabled: Bool
    @Binding var isMicrophoneMuted: Bool
    @Binding var isSpeakerEnabled: Bool
    
    var body: some View {
        HStack(spacing: 32) {
            WaitingRoomControl(iconOff: .cameraOff,
                               iconOn: .cameraOff,
                               enabled: $isVideoEnabled)
            WaitingRoomControl(iconOff: .micOn,
                               iconOn: .micOff,
                               enabled: $isMicrophoneMuted)
            WaitingRoomControl(iconOff: .speakerOff,
                               iconOn: .speakerOn,
                               enabled: $isSpeakerEnabled)
        }
        .padding()
    }
}

struct WaitingRoomControl: View {
    let iconOff: ImageResource
    let iconOn: ImageResource
    @Binding var enabled: Bool
    
    var body: some View {
        Button {
            enabled.toggle()
        } label: {
            Image(enabled ? iconOn : iconOff)
                .clipShape(Circle())
        }

    }
}

struct WaitingRoomControlsView_Previews: PreviewProvider {
    static var previews: some View {
        WaitingRoomControlsView(isVideoEnabled: .constant(false),
                                isMicrophoneMuted: .constant(true),
                                isSpeakerEnabled: .constant(true))
            .background(Color.black)
            .previewLayout(.sizeThatFits)
    }
}
