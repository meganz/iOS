import Foundation

extension Sequence {
    func isEmpty(where predicate: (Self.Element) -> Bool) -> Bool {
        first(where: predicate) == nil
    }
    
    func isNotEmpty(where predicate: (Self.Element) -> Bool) -> Bool {
        first(where: predicate) != nil
    }
}
