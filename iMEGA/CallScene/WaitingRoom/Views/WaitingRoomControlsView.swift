import MEGASwiftUI
import SwiftUI

struct WaitingRoomControlsView: View {
    @Binding var isVideoEnabled: Bool
    @Binding var isMicrophoneMuted: Bool
    @Binding var isSpeakerEnabled: Bool
    @Binding var speakerOnIcon: ImageResource
    @Binding var isBluetoothAudioRouteAvailable: Bool
    
    var body: some View {
        HStack(spacing: 32) {
            WaitingRoomControl(iconOff: .cameraOff,
                               iconOn: .cameraOn,
                               enabled: $isVideoEnabled)
            WaitingRoomControl(iconOff: .micOn,
                               iconOn: .micOff,
                               enabled: $isMicrophoneMuted)
            WaitingRoomControl(iconOff: .speakerOff,
                               iconOn: speakerOnIcon,
                               enabled: $isSpeakerEnabled)
            .overlay(
                AirPlayButton()
                    .opacity(isBluetoothAudioRouteAvailable ? 1 : 0)
            )
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
                .resizable()
                .frame(width: 56, height: 56)
                .clipShape(Circle())
        }
    }
}

struct WaitingRoomControlsView_Previews: PreviewProvider {
    static var previews: some View {
        WaitingRoomControlsView(isVideoEnabled: .constant(false),
                                isMicrophoneMuted: .constant(true),
                                isSpeakerEnabled: .constant(true), 
                                speakerOnIcon: .constant(.speakerOn),
                                isBluetoothAudioRouteAvailable: .constant(false))
            .background(Color.black)
            .previewLayout(.sizeThatFits)
    }
}
