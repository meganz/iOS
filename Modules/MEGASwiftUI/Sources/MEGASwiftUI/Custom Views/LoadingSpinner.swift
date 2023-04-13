import SwiftUI

public struct LoadingSpinner: View {
    
    public init() {}
    
    public var body: some View {
        Spacer()
        ProgressView()
            .progressViewStyle(.circular)
        Spacer()
    }
}
