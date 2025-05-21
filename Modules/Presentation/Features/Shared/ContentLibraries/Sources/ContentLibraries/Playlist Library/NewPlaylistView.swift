import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

public struct NewPlaylistView: View {
    private let addPlaylistAction: @MainActor () -> Void
    
    public init(addPlaylistAction: @escaping @MainActor () -> Void) {
        self.addPlaylistAction = addPlaylistAction
    }
    
    public var body: some View {
        HStack(spacing: TokenSpacing._3) {
            addPlaylistButton
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                
                Text(Strings.Localizable.Videos.Tab.Playlist.Content.newPlaylist)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
    
                Spacer()
                
                Divider()
                    .background(TokenColors.Border.strong.swiftUI)
            }
        }
        .frame(height: 60)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, TokenSpacing._4)
    }
    
    private var addPlaylistButton: some View {
        Button(
            action: addPlaylistAction,
            label: {
                ZStack {
                    Circle()
                        .frame(width: 44, height: 44)
                    
                    MEGAAssets.Image.navigationBarAdd
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 22, height: 22)
                        .tint(TokenColors.Text.inverseAccent.swiftUI)
                }
            })
        .tint(TokenColors.Icon.accent.swiftUI)
        .frame(width: 44, height: 44)
    }
}

#Preview {
    NewPlaylistView { }
}
