import SwiftUI

@available(iOS, introduced: 14.0, deprecated: 15.0, message: "From iOS 15.0, please go for material ShapeStyle 😺")
struct BlurryView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Image(colorScheme == .dark ? .black : .white)
            .resizable()
            .blur(radius: 0.85)
            .opacity(0.85)
            .clipped()
    }
}

@available(iOS 14.0, *)
struct BlurryView_Previews: PreviewProvider {
    static var previews: some View {
        BlurryView()
    }
}
