import SwiftUI

struct PhotosBrowserImageCellContent: View {
    let value: Int
    
    var body: some View {
        VStack {
            Text("\(value)")
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        }
        .background(Color.red)
    }
}
