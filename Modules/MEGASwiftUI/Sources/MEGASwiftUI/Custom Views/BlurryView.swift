import SwiftUI

@available(iOS, introduced: 14.0, deprecated: 15.0, message: "From iOS 15.0, please go for material ShapeStyle 😺")
public struct BlurryView: View {
    @Environment(\.colorScheme) private var colorScheme
    let singleColorTheme: Bool
    
    init(singleColorTheme: Bool = false) {
        self.singleColorTheme = singleColorTheme
    }
    
    public var body: some View {
        Image(singleColorTheme ? .white : colorScheme == .dark ? .black : .white)
            .resizable()
            .blur(radius: 2, opaque: true)
            .opacity(0.9)
            .clipped()
    }
}
