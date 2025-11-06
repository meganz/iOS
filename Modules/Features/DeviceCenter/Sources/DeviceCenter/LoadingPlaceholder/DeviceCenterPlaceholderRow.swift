import SwiftUI

struct DeviceCenterPlaceholderRow: View {
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                    .frame(width: 112, height: 16)

                RoundedRectangle(cornerRadius: 8)
                    .frame(width: 175, height: 16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(EdgeInsets(top: 20, leading: 12, bottom: 0, trailing: 12))
        .shimmering()
    }
}
