import SwiftUI

@available(iOS, introduced: 14.0, deprecated: 15.0, message: "From iOS 15.0, please go for material ShapeStyle 😺")
struct BlurryView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Image(colorScheme == .dark ? .black : .white)
            .resizable()
            .blur(radius: 2, opaque: true)
            .opacity(0.9)
            .clipped()
    }
}
