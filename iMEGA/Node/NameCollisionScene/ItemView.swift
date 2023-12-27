import MEGASwiftUI
import SwiftUI

struct ItemView: View {
    @Environment(\.colorScheme) private var colorScheme
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
                    .foregroundColor(.primary)
                    .font(.subheadline.bold())
                if let date = date {
                    Text(date)
                        .foregroundColor(.primary)
                        .font(.caption)
                }
                if let size = size {
                    Text(size)
                        .foregroundColor(.primary)
                        .font(.caption)
                }
            }
            Spacer()
        }
        .padding(10)
        .background(colorScheme == .dark ? Color(MEGAAppColor.Black._2C2C2E.uiColor) : MEGAAppColor.White._FFFFFF.color)
        .overlay(RoundedRectangle(cornerRadius: 8)
            .stroke(colorScheme == .dark ? MEGAAppColor.Gray._EBEBF5.color.opacity(0.2) : MEGAAppColor.Black._000000.color.opacity(0.1), lineWidth: 1)
        )
    }
}
