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
        .background(colorScheme == .dark ? MEGAAppColor.Yellow._FED42926.color : MEGAAppColor.Yellow._FED429.color)
    }
    
    private var text: some View {
        Text(Strings.Localizable.Meetings.ScheduleMeeting.WaitingRoomWarningBanner.title)
            .font(.caption2.bold())
            .foregroundColor(colorScheme == .dark ? MEGAAppColor.Yellow._FFD60A.color: MEGAAppColor.Yellow._9D8319.color)
    }
    
    private var closeButton: some View {
        Button {
            withAnimation {
                showBanner = false
                dismissAction?()
            }
        } label: {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(colorScheme == .dark ? MEGAAppColor.Yellow._FFD60A.color: MEGAAppColor.Yellow._9D8319.color)
        }
    }
}

struct WaitingRoomWarningBannerView_Previews: PreviewProvider {
    static var previews: some View {
        WaitingRoomWarningBannerView(showBanner: .constant(true))
            .previewLayout(.sizeThatFits)
    }
}
