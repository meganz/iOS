import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct ChatRoomParticipantView: View {
    @Environment(\.layoutDirection) private var layoutDirection

    @ObservedObject var viewModel: ChatRoomParticipantViewModel
    
    private enum Constants {
        static let viewPadding: CGFloat = 10
        static let viewHeight: CGFloat = 65
        static let avatarViewSize = CGSize(width: 40, height: 40)
        static let statusViewSize: CGFloat = 6
        static let verticalSpacing: CGFloat = 4
    }
    
    var body: some View {
        HStack {
            UserAvatarView(viewModel: viewModel.userAvatarViewModel, size: Constants.avatarViewSize)
            VStack {
                Spacer()
                HStack {
                    VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
                        HStack {
                            Text(viewModel.name)
                                .font(.subheadline)
                            Color(viewModel.chatStatus.uiColor)
                                .frame(width: Constants.statusViewSize, height: Constants.statusViewSize)
                                .clipShape(Circle())
                        }
                        if let chatStatusString = viewModel.chatStatus.localizedIdentifier {
                            Text(chatStatusString)
                                .font(.caption)
                        }
                    }
                    Spacer()
                    ChatRoomParticipantPrivilegeView(chatRoomParticipantPrivilege: viewModel.participantPrivilege)
                        .onTapGesture {
                            viewModel.privilegeTapped()
                        }
                }
                Spacer()
                if !viewModel.isMyUser {
                    Divider()
                }
            }
        }
        .padding(.trailing, Constants.viewPadding)
        .frame(height: Constants.viewHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.chatParticipantTapped()
        }
        .actionSheet(isPresented: $viewModel.showPrivilegeOptions) {
            ActionSheet(title: Text(Strings.Localizable.permissions), buttons: privilegeOptionsSheetButtons())
        }
        .background()
    }
    
    private func privilegeOptionsSheetButtons() -> [ActionSheet.Button] {
        var buttons = viewModel.privilegeOptions().map { privilege in
            ActionSheet.Button.default(Text(privilege.localizedTitle)) {
                viewModel.privilegeOptionTapped(privilege)
            }
        }
        buttons.append(ActionSheet.Button.destructive(Text(Strings.Localizable.removeParticipant)) {
            viewModel.removeParticipantTapped()
        })
        buttons.append(ActionSheet.Button.cancel())
        return buttons
    }
}
