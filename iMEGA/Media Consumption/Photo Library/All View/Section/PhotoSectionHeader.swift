import MEGASwiftUI
import SwiftUI

struct PhotoSectionHeader<T: PhotoDateSection>: View {
    let section: T

    var body: some View {
        HStack {
            Text(section.attributedTitle)
                .padding(EdgeInsets(top: 5, leading: 12, bottom: 5, trailing: 12))
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
                .padding(EdgeInsets(top: 15, leading: 8, bottom: 20, trailing: 8))

            Spacer()
        }
    }
}
