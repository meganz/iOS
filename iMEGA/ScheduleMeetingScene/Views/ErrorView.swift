import SwiftUI

struct ErrorView: View {
    let error: String
    
    var body: some View {
        Text(error)
            .font(.footnote)
            .foregroundColor(MEGAAppColor.Red._F30C14.color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
    }
}
