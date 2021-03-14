
import SwiftUI

struct GridView: View {
    let items: [QuickAccessItemModel]
    
    var columns: [GridItem] = [
        GridItem(.flexible(), spacing: 0),
        GridItem(.flexible(), spacing: 0)
    ]

    var body: some View {
            GeometryReader { geometry in
                LazyVGrid(
                    columns: columns,
                    alignment: .center,
                    spacing: 0
                ) {
                    Section() {
                        ForEach(0...items.count-1, id: \.self) { index in
                            if let url = items[index].url {
                                Link(destination: url, label: {
                                    DetailItemView(item: items[index])
                                        .frame(maxWidth: .infinity, maxHeight: geometry.size.height * 0.25)
                                })
                            } else {
                                DetailItemView(item: items[index])
                                    .frame(maxWidth: .infinity, maxHeight: geometry.size.height * 0.25)
                            }
                        }
                    }
                }
            }
    }
}
