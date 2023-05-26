import SwiftUI

struct AboutItemView: View {
    var title: String
    var subtitle: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.body)
            Text(subtitle)
                .font(.callout)
                .foregroundColor(Color(UIColor.secondaryLabel))
        }
    }
}
