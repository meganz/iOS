import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct ChatRoomLinkView: View {

    @StateObject var viewModel: ChatRoomLinkViewModel

    var body: some View {
        VStack {
            ToggleView(
                image: nil,
                text: Strings.Localizable.Meetings.Info.meetingLink,
                isOn: $viewModel.isMeetingLinkOn.onChange { isMeetingLinkOn in
                    viewModel.update(enableMeetingLinkTo: isMeetingLinkOn)
                }
            )
            .disabled(!viewModel.isMeetingLinkUIEnabled)
            
            if viewModel.isMeetingLinkOn {
                Button {
                    viewModel.shareMeetingLinkTapped()
                } label: {
                    Text(Strings.Localizable.Meetings.Action.shareLink)
                        .padding(.horizontal)
                        .foregroundStyle(TokenColors.Support.success.swiftUI)
                }
                Divider()
            }
        }
        .alert(isPresented: $viewModel.showChatLinksMustHaveCustomTitleAlert) {
            Alert(title: Text(Strings.Localizable.chatLink),
                        message: Text(Strings.Localizable.toCreateAChatLinkYouMustNameTheGroup),
                        dismissButton: .default(Text(Strings.Localizable.ok)))
        }
        .actionSheet(isPresented: $viewModel.showShareMeetingLinkOptions) {
            ActionSheet(title: Text(Strings.Localizable.Meetings.Info.ShareOptions.title), buttons: shareOptionsSheetButtons())
        }
        .background()
    }
    
    private func shareOptionsSheetButtons() -> [ActionSheet.Button] {
        var buttons = viewModel.shareOptions().map { shareOption in
            ActionSheet.Button.default(Text(shareOption.localizedTitle)) {
                viewModel.shareOptionTapped(shareOption)
            }
        }
        buttons.append(ActionSheet.Button.cancel())
        return buttons
    }
}
