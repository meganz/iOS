import MEGASwiftUI
import SwiftUI

struct ScheduledMeetingOccurrencesView: View {
    
    @ObservedObject var viewModel: ScheduledMeetingOccurrencesViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.displayOccurrences) { occurrence in
                ScheduledMeetingOccurrencesContentView(
                    occurrence: occurrence,
                    chatRoomAvatarViewModel: viewModel.chatRoomAvatarViewModel
                )
                .contentShape(Rectangle())
                .contextMenu {
                    if let contextMenuOptions = viewModel.contextMenuOptions {
                        ForEach(contextMenuOptions) { contextMenuOption in
                            Button {
                                contextMenuOption.action(occurrence)
                            } label: {
                                HorizontalImageTextLabel(image: UIImage(resource: contextMenuOption.image), text: contextMenuOption.title)
                            }
                        }
                    }
                }
            }
            if viewModel.seeMoreOccurrencesVisible {
                SeeMoreOccurrencesView {
                    Task {
                        await viewModel.seeMoreTapped()
                    }
                }
                .background()
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .edgesIgnoringSafeArea([.top, .bottom])
        .alert(isPresented: $viewModel.showCancelMeetingAlert) {
            let cancelMeetingAlertData = viewModel.cancelMeetingAlertData()
            return Alert(title: Text(cancelMeetingAlertData.title),
                         message: Text(cancelMeetingAlertData.message),
                         primaryButton: .default(Text(cancelMeetingAlertData.primaryButtonTitle), action: {
                cancelMeetingAlertData.primaryButtonAction?()
            }), secondaryButton: .cancel(Text(cancelMeetingAlertData.secondaryButtonTitle))
            )
        }
    }
}

struct ScheduledMeetingOccurrencesContentView: View {
    let occurrence: ScheduleMeetingOccurrence
    let chatRoomAvatarViewModel: ChatRoomAvatarViewModel?
    
    var body: some View {
        OccurrenceView(
            occurrence: occurrence,
            chatRoomAvatarViewModel: chatRoomAvatarViewModel
        )
        .background()
        .listRowSeparator(.hidden)
    }
}
