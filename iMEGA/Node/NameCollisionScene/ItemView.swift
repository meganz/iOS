import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct ItemView: View {
    var name: String
    var size: String?
    var date: String?
    var imageUrl: URL?
    var imagePlaceholder: MEGAFileTypeResource
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            (Image(contentsOfFile: imageUrl?.path) ?? Image(imagePlaceholder))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40.0, height: 40.0)
                .clipped()
            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .font(.subheadline.bold())
                if let date = date {
                    Text(date)
                        .font(.caption)
                }
                if let size = size {
                    Text(size)
                        .font(.caption)
                }
            }
            .foregroundStyle(TokenColors.Text.primary.swiftUI)
            Spacer()
        }
        .padding(10)
        .background()
        .overlay(RoundedRectangle(cornerRadius: 8)
            .stroke(TokenColors.Border.strong.swiftUI, lineWidth: 1)
        )
    }
}
