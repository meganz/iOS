import SwiftUI

struct ChatRoomLinkView: View {
    @Environment(\.colorScheme) private var colorScheme

    @StateObject var viewModel: ChatRoomLinkViewModel

    var body: some View {
        VStack {
            ToogleView(
                image: Asset.Images.Meetings.Info.meetingLink.name,
                text: Strings.Localizable.Meetings.Info.meetingLink,
                isOn: $viewModel.isMeetingLinkOn) { newValue in
                viewModel.meetingLinkValueChanged(to: newValue)
            }
            .disabled(viewModel.isMeetingLinkDisabled)
            if viewModel.isMeetingLinkOn {
                Button {
                    viewModel.shareMeetingLinkTapped()
                } label: {
                    Text(Strings.Localizable.Meetings.Action.shareLink)
                        .padding(.horizontal)
                        .foregroundColor(Color(UIColor.mnz_green00A886()))
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
        .background(colorScheme == .dark ? Color(Colors.General.Black._1c1c1e.name) : .white)
    }
    
    private func shareOptionsSheetButtons() -> [ActionSheet.Button] {
        return viewModel.shareOptions().map { shareOption in
            ActionSheet.Button.default(Text(shareOption.localizedTitle)) {
                viewModel.shareOptionTapped(shareOption)
            }
        }
    }
}
