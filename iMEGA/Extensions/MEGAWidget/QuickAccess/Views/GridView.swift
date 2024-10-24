import MEGASwiftUI
import SwiftUI

struct GridView: View {
    let items: [QuickAccessItemModel]
    
    private let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 0), count: 2)
    
    var body: some View {
        GeometryReader { proxy in
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(0..<items.count, id: \.self) { index in
                    cell(for: items[index], maxHeight: proxy.size.height * CGFloat(0.25))
                }
            }
        }
    }
    
    private func cell(for item: QuickAccessItemModel, maxHeight: CGFloat) -> some View {
        GridCell(item: item)
            .frame(maxWidth: .infinity, maxHeight: maxHeight)
            .applyWidgetAccent()
    }
}

private struct GridCell: View {
    let item: QuickAccessItemModel
    
    var body: some View {
        if let url = item.url {
            Link(destination: url) {
                DetailItemView(item: item)
            }
        } else {
            DetailItemView(item: item)
        }
    }
}
