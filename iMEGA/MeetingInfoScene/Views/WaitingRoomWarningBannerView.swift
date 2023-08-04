import SwiftUI

struct WaitingRoomWarningBannerView: View {
    @Binding var showBanner: Bool
    
    var body: some View {
        HStack {
            if let url = URL(string: "https://help.mega.io/wp-admin/post.php?post=3005&action=edit") {
                buildBannerText(with: url)
            }
            Spacer()
            closeButton
        }
        .padding()
        .background(Color(Colors.General.Yellow.fed429.name))
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
            .foregroundColor(Color(Colors.General.Yellow._9D8319.name))
    }
    
    var closeButton: some View {
        Button {
            withAnimation {
                showBanner = false
            }
        } label: {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(Color(Colors.General.Yellow._9D8319.name))
        }
    }
}

struct WaitingRoomWarningBannerView_Previews: PreviewProvider {
    static var previews: some View {
        WaitingRoomWarningBannerView(showBanner: .constant(true))
            .previewLayout(.sizeThatFits)
    }
}
