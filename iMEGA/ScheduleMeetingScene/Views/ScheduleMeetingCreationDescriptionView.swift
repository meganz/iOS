
import SwiftUI

struct ScheduleMeetingCreationDescriptionView: View {
    @ObservedObject var viewModel: ScheduleMeetingViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isBottomViewInFocus: Bool

    var body: some View {
        VStack {
            VStack {
                Divider()
                
                Group {
                    if #available(iOS 15.0, *) {
                        FocusableTextDescriptionView(descriptionText: $viewModel.meetingDescription) { isBottomViewInFocus = $0 }
                    } else {
                        TextDescriptionView(descriptionText: $viewModel.meetingDescription)
                    }
                }
                .opacity(viewModel.shouldAllowEditingMeetingDescription ? 1.0 : 0.3)
                .disabled(!viewModel.shouldAllowEditingMeetingDescription)
               
                Divider()
            }
            .background(colorScheme == .dark ? Color(Colors.General.Black._1c1c1e.name) : .white)
            
            if viewModel.meetingDescriptionTooLong {
                ErrorView(error: Strings.Localizable.Meetings.ScheduleMeeting.Description.lenghtError)
            }
        }
        .padding(.bottom, 20)
    }
}
