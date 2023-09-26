import MEGAL10n
import SwiftUI

struct EmptyAlbumView: View {
    let image: UIImage
    let title: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 32) {
            Image(uiImage: image)
                .resizable()
                .frame(width: 120, height: 120)
            
            Text(title)
                .font(.body)
        }
    }
}

struct EmptyAlbumView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyAlbumView(image: UIImage(systemName: "folder") ?? UIImage(),
                       title: "Title to show for empty state")
        .previewLayout(.sizeThatFits)
    }
}
