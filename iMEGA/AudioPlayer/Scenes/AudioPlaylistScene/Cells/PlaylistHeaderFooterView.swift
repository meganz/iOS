import MEGADesignToken
import MEGAL10n
import SwiftUI

struct PlaylistHeaderFooterView: View {
    let title: String
    
    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundColor(TokenColors.Text.primary.swiftUI)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
            
            Rectangle()
                .fill(TokenColors.Border.strong.swiftUI)
                .frame(height: 0.5)
        }
        .padding(.top, 10)
        .background(TokenColors.Background.page.swiftUI)
    }
}

final class PlaylistHeaderFooterHostView: UITableViewHeaderFooterView {
    func configureHeader(for section: Int) {
        let title = section == 0
            ? Strings.Localizable.Media.Audio.Playlist.Section.NowPlaying.title
            : Strings.Localizable.Media.Audio.Playlist.Section.Next.title
        
        contentConfiguration = UIHostingConfiguration {
            PlaylistHeaderFooterView(title: title)
        }
        .margins(.all, 0)
    }
}
