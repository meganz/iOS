import SwiftUI
import UIKit

/// Shows an image file at its natural size, or smaller to fit the screen.
struct ImageFileView: View {
    let entry: TestFileEntry

    var body: some View {
        Group {
            if let image = UIImage(contentsOfFile: entry.url.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: image.size.width, maxHeight: image.size.height)
                    .padding()
            } else {
                ContentUnavailableView("Cannot open the image", systemImage: "photo")
            }
        }
        .navigationTitle(entry.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
