import FileProvider
import Foundation

public extension NSFileProviderPage {
    /// A page that continues an enumeration at `offset`, the position of its first item among the container's
    /// children.
    init(offset: Int) {
        self.init(Data("\(offset)".utf8))
    }

    /// Where in the container's children this page starts. The system starts every enumeration with one of its
    /// initial pages, which are not numbers and so start at the beginning.
    var offset: Int {
        guard let offset = Int(String(decoding: rawValue, as: UTF8.self)), offset >= 0 else {
            return 0
        }
        return offset
    }
}
