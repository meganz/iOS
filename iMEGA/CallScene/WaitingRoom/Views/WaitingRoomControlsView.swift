import MEGADesignToken
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
            WaitingRoomControl(iconOff: .callControlCameraDisabled,
                               iconOn: .callControlCameraEnabled,
                               enabled: $isVideoEnabled)
            WaitingRoomControl(iconOff: .callControlMicDisabled,
                               iconOn: .callControlMicEnabled,
                               enabled: $isMicrophoneMuted)
            WaitingRoomControl(iconOff: .callControlSpeakerDisabled,
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
                .frame(width: 24, height: 24)
        }
        .frame(maxWidth: 56, maxHeight: 56, alignment: .center)
        .background(enabled ? TokenColors.Button.secondary.swiftUI : TokenColors.Button.primary.swiftUI)
        .clipShape(Circle())
    }
}

@available(iOS 17.0, *)
#Preview(traits: .sizeThatFitsLayout) {
    WaitingRoomControlsView(isVideoEnabled: .constant(false),
                            isMicrophoneMuted: .constant(true),
                            isSpeakerEnabled: .constant(true),
                            speakerOnIcon: .constant(.callControlSpeakerEnabled),
                            isBluetoothAudioRouteAvailable: .constant(false))
    .background(Color(.black000000))
}
