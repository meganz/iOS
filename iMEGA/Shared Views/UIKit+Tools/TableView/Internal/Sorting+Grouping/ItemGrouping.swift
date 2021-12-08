import Foundation

protocol ItemGrouping {
    
    associatedtype Item: Aggregatable

    var itemCount: Int { get }

    var title: String? { get }

    var key: AnyHashable? { get }
    
    func item(at index: Int) -> Item?
}
