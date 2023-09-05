import MEGAL10n
import SwiftUI

struct EmptyAlbumView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 32) {
            Image(uiImage: Asset.Images.Home.allPhotosEmptyState.image)
                .resizable()
                .frame(width: 120, height: 120)
            
            Text(Strings.Localizable.CameraUploads.Albums.Empty.title)
                .font(.body)
        }
    }
}

struct EmptyAlbumView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyAlbumView()
            .previewLayout(.sizeThatFits)
    }
}
