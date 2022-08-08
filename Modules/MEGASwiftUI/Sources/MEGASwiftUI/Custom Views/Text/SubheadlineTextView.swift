
import SwiftUI

public struct SubheadlineTextView: View {
    var text: String
    
    public init(text: String) {
        self.text = text
    }
    
    public var body: some View {
        Text(text)
            .font(.subheadline)
    }
}
