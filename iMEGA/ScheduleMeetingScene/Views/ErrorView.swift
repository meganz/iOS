import SwiftUI

struct ErrorView: View {
    let error: String
    
    var body: some View {
        Text(error)
            .font(.footnote)
            .foregroundColor(Color(UIColor.mnz_redF30C14()))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
    }
}
