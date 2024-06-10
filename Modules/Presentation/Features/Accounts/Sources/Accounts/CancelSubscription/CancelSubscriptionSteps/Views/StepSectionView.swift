import MEGADesignToken
import SwiftUI

struct StepSectionView: View {
    let sectionTitle: String
    let steps: [Step]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(sectionTitle)
                .font(.subheadline)
                .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : .primary)
                .padding(.top, 16)
            
            ForEach(Array(steps.enumerated()), id: \.offset) { _, step in
                Group {
                    Text(step.attributedText)
                }
                .font(.subheadline)
                .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.secondary.swiftUI : .secondary)
            }
            .padding(.horizontal, 4)
        }
    }
}
