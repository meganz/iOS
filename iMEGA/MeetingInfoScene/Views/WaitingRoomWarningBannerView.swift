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
        .background(colorScheme == .dark ? Color(UIColor.yellowFED42926) : Color(UIColor.yellowFED429))
    }
    
    private var text: some View {
        Text(Strings.Localizable.Meetings.ScheduleMeeting.WaitingRoomWarningBanner.title)
            .font(.caption2.bold())
            .foregroundColor(colorScheme == .dark ? Color(UIColor.yellowFFD60A): Color(UIColor.yellow9D8319))
    }
    
    private var closeButton: some View {
        Button {
            withAnimation {
                showBanner = false
                dismissAction?()
            }
        } label: {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(colorScheme == .dark ? Color(UIColor.yellowFFD60A): Color(UIColor.yellow9D8319))
        }
    }
}

struct WaitingRoomWarningBannerView_Previews: PreviewProvider {
    static var previews: some View {
        WaitingRoomWarningBannerView(showBanner: .constant(true))
            .previewLayout(.sizeThatFits)
    }
}
