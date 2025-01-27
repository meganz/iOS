import MEGASwift
import SwiftUI

@MainActor
public final class MarkdownSupportTextViewModel: ObservableObject {
    @Published var textChunks: [LocalizedStringKey] = []
    private var string: String = ""
    
    public init(string: String) {
        self.string = string
    }
    
    public func loadText() {
        guard string.isNotEmpty else { return }
        
        let lines = string.split(separator: "\n", omittingEmptySubsequences: false)
        
        for line in lines {
            textChunks.append(
                LocalizedStringKey(String(line))
            )
        }
    }
}
