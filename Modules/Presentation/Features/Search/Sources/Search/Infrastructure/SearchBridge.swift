/// This class facilitates communication between the parent of the search feature and
///  the search view model.
///  Acts as an abstraction to not pollute view model interface with many closures and makes testing easier
import Foundation
import UIKit

public class SearchBridge {
    public init(
        selection: @escaping (SearchResult) -> Void,
        context: @escaping (SearchResult, UIButton) -> Void
    ) {
        self.selection = selection
        self.context = context
    }
    
    var selection: (SearchResult) -> Void
    var context: (SearchResult, UIButton) -> Void
    
    public var queryChanged: (String) -> Void = { _ in }
    public var queryCleaned: () -> Void = { }
    public var searchCancelled: () -> Void = { }
    public var updateBottomInset: (CGFloat) -> Void = { _ in  }
}
