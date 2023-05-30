import SwiftUI

struct SharedLinkView: View {
    var body: some View {
        Image(Asset.Images.SharedItems.linksSegmentControler.name)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 15, height: 15)
            .foregroundColor(.white)
    }
}
