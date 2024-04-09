import MEGAL10n
import SwiftUI

struct WaitingRoomParticipantView: View {
    @ObservedObject var viewModel: WaitingRoomParticipantViewModel
    
    private enum Constants {
        static let viewPadding: CGFloat = 16
        static let viewHeight: CGFloat = 60
        static let avatarViewSize = CGSize(width: 40, height: 40)
    }
    
    var body: some View {
        contentView
            .alert(Strings.Localizable.Chat.Call.WaitingRoom.Alert.Message.denyAccess(viewModel.name), isPresented: $viewModel.showConfirmDenyAlert) {
                Button { } label: {
                    Text(Strings.Localizable.Chat.Call.WaitingRoom.Alert.Button.cancel)
                }
                Button {
                    viewModel.confirmDenyTapped()
                } label: {
                    Text(Strings.Localizable.Chat.Call.WaitingRoom.Alert.Button.confirmDeny)
                }
                .keyboardShortcut(.defaultAction)
            }
    }
    
    var contentView: some View {
        HStack {
            UserAvatarView(viewModel: viewModel.userAvatarViewModel, size: Constants.avatarViewSize)
            VStack {
                Spacer()
                HStack {
                    Text(viewModel.name)
                        .font(.subheadline)
                        .foregroundColor(MEGAAppColor.White._FFFFFF.color)
                    Spacer()
                    Button {
                        viewModel.denyTapped()
                    } label: {
                        Image(.waitingRoomDeny)
                    }
                    Button {
                        viewModel.admitTapped()
                    } label: {
                        Image(.waitingRoomAdmit)
                    }
                    .opacity(viewModel.admitButtonDisabled ? 0.5 : 1.0)
                    .disabled(viewModel.admitButtonDisabled)
                }
                .padding(.trailing, Constants.viewPadding)
                Spacer()
                Divider()
                    .background(MEGAAppColor.Gray._545458.color.opacity(0.65))
            }
        }
        .frame(height: Constants.viewHeight)
        .contentShape(Rectangle())
    }
}
