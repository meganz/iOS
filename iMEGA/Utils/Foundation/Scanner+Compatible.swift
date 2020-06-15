import Foundation

extension Scanner {

    func scanTo(_ string: String) -> String? {
        if #available(iOS 13.0, *) {
            return scanUpToString(string)
        } else {
            var scanned: NSString?
            scanUpTo(string, into: &scanned)
            return scanned.map(String.init)
        }
    }
}
