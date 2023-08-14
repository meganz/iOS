import SwiftUI

struct WaitingRoomWarningBannerView: View {
    @Binding var showBanner: Bool
    var dismissAction: (() -> Void)?
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            if let url = URL(string: "https://help.mega.io/wp-admin/post.php?post=3005&action=edit") {
                buildBannerText(with: url)
            }
            Spacer()
            closeButton
        }
        .padding()
        .background(colorScheme == .dark ? Color(Colors.General.Yellow.fed42926.name) : Color(Colors.General.Yellow.fed429.name))
    }
    
    private func buildBannerText(with url: URL) -> some View {
        Link(destination: url) {
            Group {
                buildText(with: Strings.Localizable.Meetings.ScheduleMeeting.WaitingRoomWarningBanner.title)
                + buildText(with: " ")
                + buildText(with: Strings.Localizable.Meetings.ScheduleMeeting.WaitingRoomWarningBanner.learnMore)
                    .underline()
            }
            .multilineTextAlignment(.leading)
        }
    }
    
    private func buildText(with title: String) -> Text {
        Text(title)
            .font(.caption2)
            .bold()
            .foregroundColor(colorScheme == .dark ? Color(Colors.General.Yellow.ffd60A.name): Color(Colors.General.Yellow._9D8319.name))
    }
    
    var closeButton: some View {
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
