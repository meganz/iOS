import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct ChatRoomLinkNonHostView: View {
    @StateObject var viewModel: ChatRoomLinkViewModel

    var body: some View {
        VStack {
            DisclosureView(
                image: .meetingLink,
                text: Strings.Localizable.Meetings.Info.shareMeetingLink) {
                    viewModel.shareMeetingLinkTapped()
                }
                .background()
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
