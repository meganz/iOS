import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct WaitingRoomView: View {
    @ObservedObject var viewModel: WaitingRoomViewModel
    
    private enum UI {
        static let contentBottomPadding: CGFloat = 140
    }
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                waitingRoomContentView()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .onAppear {
                viewModel.screenSize = proxy.size
            }
            .onChange(of: proxy.size) { newSize in
                viewModel.screenSize = newSize
            }
        }
        .ignoresSafeArea(.keyboard)
        .overlay(
            waitingRoomMessageView()
            , alignment: .top
        )
        .overlay(
            waitingRoomBottomView()
            , alignment: .bottom
        )
    }

    @ViewBuilder
    func waitingRoomContentView() -> some View {
        if viewModel.isVideoEnabled, let videoImage = viewModel.videoImage {
            GeometryReader { proxy in
                let bottomPadding = viewModel.isLandscape ? 0.0 : UI.contentBottomPadding
                let videoSize = viewModel.calculateVideoSize()
                Image(uiImage: videoImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: videoSize.width, height: videoSize.height)
                    .cornerRadius(16)
                    .position(x: proxy.size.width / 2, y: (proxy.size.height - bottomPadding) / 2 )
            }
        }
        
        if let userAvatar = viewModel.userAvatar {
            WaitingRoomUserAvatarView(avatar: Image(uiImage: userAvatar))
                .padding(.bottom, UI.contentBottomPadding)
                .opacity(viewModel.isVideoEnabled ? 0 : 1)
        }
    }
    
    func waitingRoomMessageView() -> some View {
        WaitingRoomMessageView(title: viewModel.waitingRoomMessage)
            .padding(26)
            .opacity(viewModel.showWaitingRoomMessage ? 1 : 0)
    }
    
    func waitingRoomBottomView() -> some View {
        VStack(spacing: 0) {
            WaitingRoomControlsView(
                isVideoEnabled: $viewModel.isVideoEnabled.onChange { enable in
                    Task { @MainActor in
                        viewModel.enableLocalVideo(enabled: enable)
                    }
                },
                isMicrophoneMuted: $viewModel.isMicrophoneMuted.onChange { mute in
                    Task { @MainActor in
                        viewModel.muteLocalMicrophone(mute: mute)
                    }
                },
                isSpeakerEnabled: $viewModel.isSpeakerEnabled.onChange { enable in
                    Task { @MainActor in
                        viewModel.enableLoudSpeaker(enabled: enable)
                    }
                },
                speakerOnIcon: $viewModel.speakerOnIcon, 
                isBluetoothAudioRouteAvailable: $viewModel.isBluetoothAudioRouteAvailable
            )
            ZStack {
                Spacer()
                    .opacity(viewModel.viewState == .waitForHostToLetIn ? 1 : 0)
                
                ProgressView()
                    .opacity(viewModel.isJoining ? 1 : 0)
                
                WaitingRoomJoinPanelView(
                    tapJoinAction: viewModel.tapJoinAction,
                    appearFocused: viewModel.viewState == .guestUserSetup)
                .opacity(viewModel.viewState == .guestUserSetup ? 1 : 0)
            }
            .frame(height: viewModel.calculateBottomPanelHeight())
        }
    }
}
