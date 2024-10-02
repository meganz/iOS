import Foundation
import SwiftUI

public struct NavigationTitleView: View {
    public let title: String
    public let subtitle: String?
    
    @Environment(\.colorScheme) private var colorScheme

    public init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
    
    public var body: some View {
        Group {
            if let subtitle {
                VStack {
                    Text(title)
                        .font(.subheadline)
                        .bold()
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.caption)
                }
            } else {
                Text(title)
                    .font(.headline)
                    .bold()
            }
        }
        .foregroundColor(colorScheme == .dark ? .white : .black)
    }
}

@available(iOS 17.0, *)
#Preview(traits: .sizeThatFitsLayout) {
    NavigationTitleView(title: "Test Title.jpeg", subtitle: "Album Link")
}
