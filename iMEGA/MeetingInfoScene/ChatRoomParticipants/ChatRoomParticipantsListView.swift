import MEGADesignToken
import MEGAL10n
import SwiftUI

struct ChatRoomParticipantsListView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @ObservedObject var viewModel: ChatRoomParticipantsListViewModel
    
    private enum Constants {
        static let spacing: CGFloat = 0
        static let textOpacity: CGFloat = 0.6
    }
    
    var body: some View {
        VStack(spacing: Constants.spacing) {
            HStack {
                Text(Strings.Localizable.Meetings.Panel.participantsCount(viewModel.totalParticipantsCount))
                    .font(.footnote)
                    .foregroundColor(TokenColors.Text.secondary.swiftUI)
                Spacer()
            }
            .padding()
            
            if viewModel.shouldShowAddParticipants {
                AddParticipantsView()
                    .onTapGesture {
                        viewModel.addParticipantTapped()
                    }
            }
            
            ForEach(viewModel.chatRoomParticipants) { participantViewModel in
                ChatRoomParticipantView(viewModel: participantViewModel)
            }
            ChatRoomParticipantView(viewModel: viewModel.myUserParticipant)
            Divider()

            if viewModel.showExpandCollapseButton {
                SeeMoreParticipantsView(isExpanded: viewModel.listExpanded)
                    .onTapGesture {
                        viewModel.seeMoreParticipantsTapped()
                    }
            }
        }
    }
}
