import SwiftUI

@available(iOS 14.0, *)
struct CardImage: View {
    let imageURL: URL?
    
    var body: some View {
        if let path = imageURL?.path,
           let coverPhoto = UIImage(contentsOfFile: path) {
            Image(uiImage: coverPhoto)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipped()
        } else {
            Image("photoCardPlaceholder")
        }
    }
}
