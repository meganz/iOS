import MEGAL10n
import SwiftUI

struct ScheduleMeetingCreationDescriptionView: View {
    @ObservedObject var viewModel: ScheduleMeetingViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isBottomViewInFocus: Bool

    var body: some View {
        VStack {
            VStack {
                Divider()
                
                FocusableTextDescriptionView(descriptionText: $viewModel.meetingDescription) { isBottomViewInFocus = $0 }
                .opacity(viewModel.shouldAllowEditingMeetingDescription ? 1.0 : 0.3)
                .disabled(!viewModel.shouldAllowEditingMeetingDescription)
               
                Divider()
            }
            .background(colorScheme == .dark ? Color(.black1C1C1E) : .white)
            
            if viewModel.meetingDescriptionTooLong {
                ErrorView(error: Strings.Localizable.Meetings.ScheduleMeeting.Description.lenghtError)
            }
        }
        .padding(.bottom, 20)
    }
}
