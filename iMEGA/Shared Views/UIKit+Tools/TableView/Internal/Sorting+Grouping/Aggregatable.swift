import Foundation

protocol Aggregatable {

    associatedtype Key: Hashable

    var key: Key { get }

    var title: String { get }
}
