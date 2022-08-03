import SwiftUI
import MEGASwiftUI

@available(iOS 14.0, *)
struct PhotoSectionHeader<T: PhotoDateSection>: View {
    let section: T

    var body: some View {
        HStack {
            headerTitle(for: section)
                .padding(EdgeInsets(top: 5, leading: 12, bottom: 5, trailing: 12))
                .blurryBackground(radius: 20)
                .padding(EdgeInsets(top: 15, leading: 8, bottom: 20, trailing: 8))

            Spacer()
        }
    }

    @ViewBuilder
    private func headerTitle(for section: PhotoDateSection) -> some View {
        if #available(iOS 15.0, *) {
            Text(section.attributedTitle)
        } else {
            Text(section.title)
                .font(.subheadline.weight(.semibold))
        }
    }
}
