import MEGADesignToken
import MEGAL10n
import SwiftUI

struct ScheduleMeetingView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @ObservedObject var viewModel: ScheduleMeetingViewModel
    @Namespace var bottomViewID
    
    @State private var isBottomViewInFocus = false
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.showWaitingRoomWarningBanner {
                BannerView(
                    config: .init(
                        copy: Strings.Localizable.Meetings.ScheduleMeeting.WaitingRoomWarningBanner.title,
                        theme: .dark,
                        closeAction: viewModel.scheduleMeetingBannerDismissed
                    )
                )
                .font(.footnote.bold())
            }
            ScrollViewReader { proxy in
                ScrollView {
                    ScheduleMeetingCreationNameView(viewModel: viewModel, appearFocused: viewModel.meetingName.isEmpty)
                    if viewModel.meetingNameTooLong {
                        ErrorView(error: Strings.Localizable.Meetings.ScheduleMeeting.MeetingName.lenghtError)
                    } else {
                        ScheduleMeetingCreationFootnoteView(title: Strings.Localizable.Meetings.ScheduleMeeting.MeetingName.titleUnencrypted)
                    }
                    ScheduleMeetingCreationPropertiesView(viewModel: viewModel)
                    ScheduleMeetingCreationInvitationView(viewModel: viewModel)
                    ScheduleMeetingCreationWaitingRoomView(
                        waitingRoomEnabled: $viewModel.waitingRoomEnabled.onChange { enabled in
                            Task { @MainActor in
                                viewModel.onWaitingRoomEnabledChange(enabled)
                            }
                        },
                        shouldAllowEditingWaitingRoom: viewModel.shouldAllowEditingWaitingRoom
                    )
                    ScheduleMeetingCreationOpenInviteView(viewModel: viewModel)
                    ScheduleMeetingCreationDescriptionView(viewModel: viewModel, isBottomViewInFocus: $isBottomViewInFocus)
                    
                    Spacer()
                        .frame(height: 0)
                        .id(bottomViewID)
                }
                .onChange(of: viewModel.meetingDescription) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
                .onReceive(
                    NotificationCenter.Publisher(center: .default, name: UIResponder.keyboardDidShowNotification)
                ) { _ in
                    scrollToBottom(proxy: proxy)
                }
                .customScrollViewDismissKeyboard()
            }
        }
        .padding(.vertical)
        .background(TokenColors.Background.page.swiftUI)
        .ignoresSafeArea(.container, edges: [.top, .bottom])
        .onAppear {
            viewModel.viewAppeared()
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard isBottomViewInFocus else { return }
        withAnimation {
            proxy.scrollTo(bottomViewID, anchor: .top)
        }
    }
}
