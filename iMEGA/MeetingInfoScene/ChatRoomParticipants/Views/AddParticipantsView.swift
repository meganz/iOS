import SwiftUI

struct AddParticipantsView: View {
    @Environment(\.colorScheme) private var colorScheme
        
    private enum Constants {
        static let viewPadding: CGFloat = 10
        static let viewHeight: CGFloat = 65
        static let imageSize = CGSize(width: 60, height: 60)
        static let padding: CGFloat = 8
        static let spacing: CGFloat = 0
    }
    
    var body: some View {
        HStack(spacing: Constants.spacing)  {
            Image(Asset.Images.Chat.inviteToChat.name)
                .padding(Constants.padding)
                .frame(width: Constants.imageSize.width, height: Constants.imageSize.height)
            VStack (alignment: .leading) {
                Spacer()
                Text(Strings.Localizable.addParticipant)
                    .font(.subheadline)
                Spacer()
                Divider()
            }
        }
        .padding(.trailing, Constants.viewPadding)
        .frame(height: Constants.viewHeight)
        .contentShape(Rectangle())
        .background(colorScheme == .dark ? Color(Colors.General.Black._1c1c1e.name) : .white)
    }
}
