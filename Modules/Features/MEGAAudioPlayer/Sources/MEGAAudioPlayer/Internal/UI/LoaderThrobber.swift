import MEGAAssets
import MEGADesignToken
import SwiftUI

struct LoaderThrobber: View {
    private let revolutionDuration: Double = 1.4

    @State private var spinning = false

    var body: some View {
        MEGAAssets.Image.monoLoaderThrobberMediumRegularOutline
            .resizable()
            .scaledToFit()
            .foregroundStyle(TokenColors.Icon.primary.swiftUI)
            .rotationEffect(.degrees(spinning ? 360 : 0))
            .animation(.linear(duration: revolutionDuration).repeatForever(autoreverses: false), value: spinning)
            .onAppear { spinning = true }
    }
}

#Preview {
    LoaderThrobber()
        .frame(width: TokenSpacing._15, height: TokenSpacing._15)
        .padding()
        .background(Color.black)
}
