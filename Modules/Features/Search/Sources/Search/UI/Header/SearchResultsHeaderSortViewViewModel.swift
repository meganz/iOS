import SwiftUI

public struct SearchResultsHeaderSortViewViewModel {
    let title: String
    let icon: Image?
    let handler: () -> Void

    public init(title: String, icon: Image?, handler: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.handler = handler
    }
}
