import MEGASwiftUI
import SwiftUI

struct PhotoLibraryPlaceholderView: View {
    let isActive: Bool
    private let columns: [GridItem] = Array(
        repeating: .init(.flexible(), spacing: 4),
        count: 3
    )
    private let placeholderCount = 15
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, pinnedViews: .sectionHeaders) {
                Section(header: sectionHeader) {
                    ForEach(0..<placeholderCount, id: \.self) { _ in
                        Rectangle()
                            .aspectRatio(1.0, contentMode: .fill)
                    }
                }
            }
            .shimmering(active: isActive)
        }
        .background(Color(UIColor.systemBackground))
        .opacity(isActive ? 1 : 0)
        .animation(.smooth, value: isActive)
    }
    
    var sectionHeader: some View {
        HStack {
            RoundedRectangle(cornerRadius: 20)
                .frame(width: 100, height: 30)
                .padding(EdgeInsets(top: 11, leading: 8, bottom: 4, trailing: 8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    PhotoLibraryPlaceholderView(isActive: true)
}
