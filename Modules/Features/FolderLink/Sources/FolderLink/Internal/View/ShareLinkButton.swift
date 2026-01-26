import MEGAAssets
import MEGAL10n
import SwiftUI

struct ShareLinkButton: View {
    let link: String
    
    var body: some View {
        if let url = URL(string: link) {
            ShareLink(item: url) {
                Label {
                    Text(Strings.Localizable.General.MenuAction.ShareLink.title(1))
                } icon: {
                    Image(uiImage: MEGAAssets.UIImage.link01)
                }
            }
        }
    }
}
