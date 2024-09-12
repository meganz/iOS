import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct CallControlsView<ViewModel: CallControlsViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            CallControlView(config: .microphone(enabled: viewModel.micEnabled, action: viewModel.toggleMicTapped))
            CallControlView(config: .camera(enabled: viewModel.cameraEnabled, action: viewModel.toggleCameraTapped))
            if viewModel.routeViewVisible {
                VStack {
                    AirPlayButton(tintColor: TokenColors.Text.primary, activeTintColor: TokenColors.Text.primary)
                        .frame(maxWidth: 56, maxHeight: 56, alignment: .center)
                        .background(TokenColors.Button.secondary.swiftUI)
                        .clipShape(Circle())
                    Text(Strings.Localizable.Meetings.QuickAction.speaker)
                        .font(.caption2)
                        .foregroundColor(TokenColors.Text.primary.swiftUI)
                }
            } else {
                CallControlView(config: .speaker(enabled: viewModel.speakerEnabled, action: viewModel.toggleSpeakerTapped))
            }
            
            if viewModel.showMoreButton {
                CallControlView(config: .moreButton(action: viewModel.moreButtonTapped))
                    .onAppear {
                        Task {
                            await viewModel.checkRaiseHandBadge()
                        }
                    }
            } else {
                CallControlView(config: .switchCamera(enabled: viewModel.cameraEnabled, action: viewModel.switchCameraTapped))
            }
            CallControlView(config: .endCall(action: viewModel.endCallTapped))
        }
        .frame(maxWidth: .infinity, maxHeight: 100)
    }
}

 #Preview("Call controls all disabled") {
     CallControlsView(
        viewModel:
            MockCallControlsViewModel(
                micEnabled: false,
                cameraEnabled: false,
                speakerEnabled: false,
                routeViewVisible: false
            )
     )
 }

#Preview("Call controls all enabled no audio route") {
    CallControlsView(
        viewModel:
            MockCallControlsViewModel(
                micEnabled: true,
                cameraEnabled: true,
                speakerEnabled: true,
                routeViewVisible: false
            )
    )
 }

#Preview("Call controls mic enabled") {
    CallControlsView(
        viewModel:
            MockCallControlsViewModel(
                micEnabled: true,
                cameraEnabled: false,
                speakerEnabled: false,
                routeViewVisible: false
            )
    )
}

#Preview("Call controls camera enabled") {
    CallControlsView(
        viewModel:
            MockCallControlsViewModel(
                micEnabled: false,
                cameraEnabled: true,
                speakerEnabled: false,
                routeViewVisible: false
            )
    )
}

#Preview("Call controls audio route available") {
    CallControlsView(
        viewModel:
            MockCallControlsViewModel(
                micEnabled: false,
                cameraEnabled: true,
                speakerEnabled: false,
                routeViewVisible: true
            )
    )
}

#Preview("Call controls with more button") {
    CallControlsView(
        viewModel:
            MockCallControlsViewModel(
                micEnabled: false,
                cameraEnabled: true,
                speakerEnabled: false,
                routeViewVisible: false,
                showMoreButton: true
            )
    )
}
