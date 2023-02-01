import SwiftUI

struct ScheduledMeetingOccurrencesView: View {

    @ObservedObject var viewModel: ScheduledMeetingOccurrencesViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.diplayOccurrences) { occurrence in
                if #available(iOS 15.0, *) {
                    OccurrenceView(occurrence: occurrence, chatRoomAvatarViewModel: viewModel.chatRoomAvatarViewModel)
                        .listRowSeparator(.hidden)
                } else {
                    OccurrenceView(occurrence: occurrence, chatRoomAvatarViewModel: viewModel.chatRoomAvatarViewModel)
                }
            }
            if #available(iOS 15.0, *) {
                SeeMoreOccurrencesView {
                    viewModel.seeMoreTapped()
                }
                .listRowSeparator(.hidden)
            } else {
                SeeMoreOccurrencesView {
                    viewModel.seeMoreTapped()
                }
            }
        }
        .listStyle(.plain)
        .edgesIgnoringSafeArea([.top, .bottom])
    }
}
