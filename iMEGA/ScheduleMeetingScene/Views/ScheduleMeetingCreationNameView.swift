
import SwiftUI

struct ScheduleMeetingCreationNameView: View {
    @ObservedObject var viewModel: ScheduleMeetingViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack {
            Divider()
            TextFieldView(text: $viewModel.meetingName)
            Divider()
        }
        .background(colorScheme == .dark ? Color(Colors.General.Black._1c1c1e.name) : .white)
    }
}
