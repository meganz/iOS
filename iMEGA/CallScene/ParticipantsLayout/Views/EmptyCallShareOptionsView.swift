import MEGADesignToken
import MEGAL10n
import SwiftUI

enum EmptyCallShareOptionAction {
    case shareLink
    case copyLink
    case inviteParticipants
}

struct EmptyCallShareOptionsView: View {
    let actionHandler: (EmptyCallShareOptionAction) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(Strings.Localizable.Call.Meeting.Empty.ShareOptionsDialog.title)
                .font(.subheadline)
                .foregroundColor(TokenColors.Text.secondary.swiftUI)
                .frame(width: 250)
                .padding(.bottom)
            
            Button {
                actionHandler(.shareLink)
            } label: {
                Text(Strings.Localizable.Call.Meeting.Empty.ShareOptionsDialog.shareMeetingLink)
                    .foregroundColor(TokenColors.Text.inverseAccent.swiftUI)
            }
            .frame(width: 250, height: 50)
            .background(TokenColors.Button.primary.swiftUI)
            .cornerRadius(8)
            
            Button {
                actionHandler(.copyLink)
            } label: {
                Text(Strings.Localizable.Call.Meeting.Empty.ShareOptionsDialog.copyMeetingLink)
                    .foregroundColor(TokenColors.Text.primary.swiftUI)
            }
            .frame(width: 250, height: 50)
            .background(TokenColors.Button.secondary.swiftUI)
            .cornerRadius(8)
            
            Button {
                actionHandler(.inviteParticipants)
            } label: {
                Text(Strings.Localizable.Call.Meeting.Empty.ShareOptionsDialog.inviteParticipants)
                    .foregroundColor(TokenColors.Text.primary.swiftUI)
            }
            .frame(width: 250, height: 50)
        }
        .padding(32)
        .background(TokenColors.Background.surface1.swiftUI)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(TokenColors.Border.strong.swiftUI, lineWidth: 1)
        )
    }
}

#Preview("EmptyCallShareOptionsView") {
    EmptyCallShareOptionsView { action in
        print(action)
    }
}
