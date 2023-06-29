import SwiftUI

struct ScheduledMeetingOccurrencesView: View {

    @ObservedObject var viewModel: ScheduledMeetingOccurrencesViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.displayOccurrences) { occurrence in
                ScheduledMeetingOccurrencesContentView(occurrence: occurrence, chatRoomAvatarViewModel: viewModel.chatRoomAvatarViewModel)
                    .contentShape(Rectangle())
                    .contextMenu {
                        if let contextMenuOptions = viewModel.contextMenuOptions {
                            ForEach(contextMenuOptions) { contextMenuOption in
                                Button {
                                    contextMenuOption.action(occurrence)
                                } label: {
                                    Label(contextMenuOption.title, image: contextMenuOption.imageName)
                                }
                            }
                        }
                    }
            }
            if viewModel.seeMoreOccurrencesVisible {
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
        }
        .listStyle(.plain)
        .edgesIgnoringSafeArea([.top, .bottom])
        .alert(isPresented: $viewModel.showCancelMeetingAlert) {
            let cancelMeetingAlertData = viewModel.cancelMeetingAlertData()
            return Alert(title: Text(cancelMeetingAlertData.title),
                         message: Text(cancelMeetingAlertData.message),
                         primaryButton: .cancel(Text(cancelMeetingAlertData.primaryButtonTitle), action: {
                cancelMeetingAlertData.primaryButtonAction?()
            }), secondaryButton: .default(Text(cancelMeetingAlertData.secondaryButtonTitle))
            )
        }
    }
}

struct ScheduledMeetingOccurrencesContentView: View {
    let occurrence: ScheduleMeetingOccurence
    let chatRoomAvatarViewModel: ChatRoomAvatarViewModel?

    var body: some View {
        if #available(iOS 15.0, *) {
            OccurrenceView(occurrence: occurrence, chatRoomAvatarViewModel: chatRoomAvatarViewModel)
                .listRowSeparator(.hidden)
        } else {
            OccurrenceView(occurrence: occurrence, chatRoomAvatarViewModel: chatRoomAvatarViewModel)
        }
    }
}
