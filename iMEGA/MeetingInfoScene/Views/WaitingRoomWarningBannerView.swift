import MEGAL10n
import SwiftUI

struct WaitingRoomWarningBannerView: View {
    @Binding var showBanner: Bool
    var dismissAction: (() -> Void)?
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            text
            Spacer()
            closeButton
        }
        .padding()
        .background(colorScheme == .dark ? Color(Colors.General.Yellow.fed42926.name) : Color(Colors.General.Yellow.fed429.name))
    }
    
    private var text: some View {
        Text(Strings.Localizable.Meetings.ScheduleMeeting.WaitingRoomWarningBanner.title)
            .font(.caption2.bold())
            .foregroundColor(colorScheme == .dark ? Color(Colors.General.Yellow.ffd60A.name): Color(Colors.General.Yellow._9D8319.name))
    }
    
    private var closeButton: some View {
        Button {
            withAnimation {
                showBanner = false
                dismissAction?()
            }
        } label: {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(colorScheme == .dark ? Color(Colors.General.Yellow.ffd60A.name): Color(Colors.General.Yellow._9D8319.name))
        }
    }
}

struct WaitingRoomWarningBannerView_Previews: PreviewProvider {
    static var previews: some View {
        WaitingRoomWarningBannerView(showBanner: .constant(true))
            .previewLayout(.sizeThatFits)
    }
}
