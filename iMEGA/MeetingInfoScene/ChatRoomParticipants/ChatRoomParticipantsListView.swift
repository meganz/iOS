import SwiftUI

struct ChatRoomParticipantsListView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @ObservedObject var viewModel: ChatRoomParticipantsListViewModel
    
    private enum Constants {
        static let spacing: CGFloat = 0
        static let textOpacity: CGFloat = 0.6
    }
    
    var body: some View {
        VStack (spacing: Constants.spacing) {
            HStack {
                Text(Strings.Localizable.Meetings.Panel.participantsCount(viewModel.totalParcitipantsCount))
                    .font(.footnote)
                    .foregroundColor(colorScheme == .dark ? Color(UIColor.mnz_grayB5B5B5().withAlphaComponent(Constants.textOpacity)) : Color(UIColor.mnz_gray3C3C43().withAlphaComponent(Constants.textOpacity)))
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
