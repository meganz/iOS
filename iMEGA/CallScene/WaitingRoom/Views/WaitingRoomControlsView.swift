import MEGAAssets
import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct WaitingRoomControlsView: View {
    @Binding var isVideoEnabled: Bool
    @Binding var isMicrophoneMuted: Bool
    @Binding var isSpeakerEnabled: Bool
    @Binding var speakerOnIcon: Image
    @Binding var isBluetoothAudioRouteAvailable: Bool
    
    var body: some View {
        HStack(spacing: 32) {
            WaitingRoomControl(iconOff: MEGAAssets.Image.callControlCameraDisabled,
                               iconOn: MEGAAssets.Image.callControlCameraEnabled,
                               enabled: $isVideoEnabled)
            WaitingRoomControl(iconOff: MEGAAssets.Image.callControlMicDisabled,
                               iconOn: MEGAAssets.Image.callControlMicEnabled,
                               enabled: $isMicrophoneMuted)
            WaitingRoomControl(iconOff: MEGAAssets.Image.callControlSpeakerDisabled,
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
    let iconOff: Image
    let iconOn: Image
    @Binding var enabled: Bool
    
    var body: some View {
        Button {
            enabled.toggle()
        } label: {
            iconView
                .frame(width: 24, height: 24)
        }
        .frame(maxWidth: 56, maxHeight: 56, alignment: .center)
        .background(enabled ? TokenColors.Button.secondary.swiftUI : TokenColors.Button.primary.swiftUI)
        .clipShape(Circle())
    }
    
    @ViewBuilder
    private var iconView: some View {
        if enabled {
            iconOn.resizable()
        } else {
            iconOff.resizable()
        }
    }
}

@available(iOS 17.0, *)
#Preview(traits: .sizeThatFitsLayout) {
    WaitingRoomControlsView(isVideoEnabled: .constant(false),
                            isMicrophoneMuted: .constant(true),
                            isSpeakerEnabled: .constant(true),
                            speakerOnIcon: .constant(MEGAAssets.Image.callControlSpeakerEnabled),
                            isBluetoothAudioRouteAvailable: .constant(false))
    .background(MEGAAssets.Color.black000000)
}
