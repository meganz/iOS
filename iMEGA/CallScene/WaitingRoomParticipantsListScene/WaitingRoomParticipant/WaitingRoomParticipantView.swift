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
        if #available(iOS 15.0, *) {
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
        } else {
            contentView
                .alert(isPresented: $viewModel.showConfirmDenyAlert) {
                    Alert(title: Text(Strings.Localizable.Chat.Call.WaitingRoom.Alert.Message.denyAccess(viewModel.name)),
                          primaryButton: .default(Text(Strings.Localizable.Chat.Call.WaitingRoom.Alert.Button.cancel)),
                          secondaryButton: .default(
                            Text(Strings.Localizable.Chat.Call.WaitingRoom.Alert.Button.confirmDeny),
                            action: {
                                viewModel.confirmDenyTapped()
                            })
                    )
                }
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
                        .foregroundColor(.white)
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
                }
                .padding(.trailing, Constants.viewPadding)
                Spacer()
                Divider()
                    .background(Color(Colors.General.Gray._545458.name).opacity(0.65))
            }
        }
        .frame(height: Constants.viewHeight)
        .contentShape(Rectangle())
    }
}
