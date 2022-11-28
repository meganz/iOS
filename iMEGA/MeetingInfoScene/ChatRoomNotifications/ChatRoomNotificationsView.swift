import SwiftUI

@available(iOS 14.0, *)
struct ChatRoomNotificationsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject var viewModel: ChatRoomNotificationsViewModel

    let image: String
    let text: String
    
    var body: some View {
        VStack {
            ToogleView(image: image, text: text, isOn: $viewModel.isChatNotificationsOn) { newValue in
                viewModel.chatNotificationsValueChanged(to: newValue)
            }
            if !viewModel.isChatNotificationsOn {
                Text(viewModel.remainingDNDTime())
                    .font(.footnote)
                    .foregroundColor(colorScheme == .dark ? Color(UIColor.mnz_grayB5B5B5()) : Color(UIColor.mnz_gray848484()))
            }
        }
        .actionSheet(isPresented: $viewModel.showDNDTurnOnOptions) {
            ActionSheet(title: Text(""), buttons: actionSheetButtons())
        }
    }
    
    private func actionSheetButtons() -> [ActionSheet.Button] {
        var buttons = viewModel.dndTurnOnOptions().map { dndOption in
            ActionSheet.Button.default(Text(dndOption.localizedTitle)) {
                viewModel.turnOnDNDOption(dndOption)
            }
        }
        buttons.append(ActionSheet.Button.cancel( {
            viewModel.cancelChatNotificationsChange()
        })
        )
        return buttons
    }
}
