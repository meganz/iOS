import MEGAAssets
import MEGAL10n
import SwiftUI

public struct ShareLinkButton: View {
    private let link: String

    public init(link: String) {
        self.link = link
    }

    public var body: some View {
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
