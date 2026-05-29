import MEGAAppPresentation
import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct PhotoSectionHeader<T: PhotoDateSection>: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let section: T
    /// When true, render the pre-MediaRevamp pill-shaped header (rounded background
    /// behind the date). Caller decides — e.g. the rolled-back Album sets this to
    /// `true` so the section keeps its legacy look.
    let useLegacyStyle: Bool

    init(section: T, useLegacyStyle: Bool = false) {
        self.section = section
        self.useLegacyStyle = useLegacyStyle
    }
    
    private var backgroundColor: Color {
        colorScheme == .light ? TokenColors.Background.surface1.swiftUI : TokenColors.Background.surface2.swiftUI
    }
    
    var body: some View {
        HStack {
            if useLegacyStyle {
                Text(section.attributedTitle)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                    .padding(EdgeInsets(top: 5, leading: 12, bottom: 5, trailing: 12))
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
                    .background(backgroundColor, in: RoundedRectangle(cornerRadius: 20))
                    .padding(EdgeInsets(top: 15, leading: 8, bottom: 20, trailing: 8))
            } else {
                Text(section.title)
                    .font(.subheadline)
                    .foregroundColor(TokenColors.Text.primary.swiftUI)
                    .padding(EdgeInsets(top: TokenSpacing._3, leading: TokenSpacing._5, bottom: TokenSpacing._3, trailing: TokenSpacing._5))
            }

            Spacer()
        }
    }
}
