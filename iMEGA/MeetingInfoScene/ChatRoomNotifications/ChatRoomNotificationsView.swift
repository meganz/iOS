import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct ChatRoomNotificationsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject var viewModel: ChatRoomNotificationsViewModel
    
    var body: some View {
        VStack {
            ToggleView(
                image: .enableChatNotifications,
                text: Strings.Localizable.Meetings.Info.meetingNotifications,
                isOn: $viewModel.isChatNotificationsOn)
            if !viewModel.isChatNotificationsOn {
                Text(viewModel.remainingDNDTime())
                    .font(.footnote)
                    .foregroundColor(colorScheme == .dark ? Color(UIColor.mnz_grayB5B5B5()) : Color(UIColor.mnz_gray848484()))
            }
        }
        .actionSheet(isPresented: $viewModel.showDNDTurnOnOptions) {
            ActionSheet(title: Text(Strings.Localizable.Meetings.Info.muteMeetingNotificationsFor), buttons: actionSheetButtons())
        }
        .background()
    }
    
    private func actionSheetButtons() -> [ActionSheet.Button] {
        var buttons = viewModel.dndTurnOnOptions().map { dndOption in
            ActionSheet.Button.default(Text(dndOption.localizedTitle)) {
                viewModel.turnOnDNDOption(dndOption)
            }
        }
        buttons.append(ActionSheet.Button.cancel({
            viewModel.cancelChatNotificationsChange()
        }))
        return buttons
    }
}
