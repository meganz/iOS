import MEGAL10n
import SwiftUI

struct ScheduleMeetingCreationDescriptionView: View {
    @ObservedObject var viewModel: ScheduleMeetingViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isBottomViewInFocus: Bool

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Divider()
                
                FocusableTextDescriptionView(descriptionText: $viewModel.meetingDescription) { isBottomViewInFocus = $0 }
                .opacity(viewModel.shouldAllowEditingMeetingDescription ? 1.0 : 0.3)
                .disabled(!viewModel.shouldAllowEditingMeetingDescription)
                .frame(minHeight: 44)
                Divider()
            }
            .background(colorScheme == .dark ? MEGAAppColor.Black._1C1C1E.color : MEGAAppColor.White._FFFFFF.color)
            
            if viewModel.meetingDescriptionTooLong {
                ErrorView(error: Strings.Localizable.Meetings.ScheduleMeeting.Description.lenghtError)
            }
        }
        .padding(.bottom, 20)
    }
}
