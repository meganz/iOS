import MEGADesignToken
import SwiftUI

struct StepSectionView: View {
    let sectionTitle: String
    let steps: [Step]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(sectionTitle)
                .font(.subheadline)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .padding(.top, 16)
            
            ForEach(Array(steps.enumerated()), id: \.offset) { _, step in
                Group {
                    Text(step.attributedText)
                }
                .font(.subheadline)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            }
            .padding(.horizontal, 4)
        }
    }
}
