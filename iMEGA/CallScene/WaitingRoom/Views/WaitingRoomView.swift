import SwiftUI

struct WaitingRoomView: View {
    @ObservedObject var viewModel: WaitingRoomViewModel
    
    var body: some View {
        ZStack {
            WaitingRoomUserAvatarView(avatar: .constant(Image(Color.red, CGSize(width: 100, height: 100))))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .overlay(
            waitingRoomMessageView()
                .opacity(viewModel.viewState == .waitForHostToLetIn ? 1 : 0)
            , alignment: .top
        )
        .overlay(
            waitingRoomBottomView()
            , alignment: .bottom
        )
    }
    
    func waitingRoomMessageView() -> some View {
        WaitingRoomMessageView(title: Strings.Localizable.Meetings.WaitingRoom.Message.waitForHostToLetYouIn)
            .padding(26)
    }
    
    func waitingRoomBottomView() -> some View {
        VStack(spacing: 0) {
            WaitingRoomControlsView(isVideoEnabled: $viewModel.isVideoEnabled,
                                    isMicrophoneEnabled: $viewModel.isMicrophoneEnabled,
                                    isSpeakerEnabled: $viewModel.isSpeakerEnabled)
            ZStack {
                Spacer()
                    .opacity(viewModel.viewState == .waitForHostToLetIn ? 1 : 0)
                
                ProgressView()
                    .opacity(viewModel.viewState == .guestJoining ? 1 : 0)
                
                WaitingRoomJoinPanelView(tapJoinAction: viewModel.tapJoinAction)
                .opacity(viewModel.viewState == .guestJoin ? 1 : 0)
            }
            .frame(height: viewModel.viewState == .guestJoin ? 142 : 100)
        }
    }
}
