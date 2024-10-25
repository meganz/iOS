import Foundation

protocol Converting {
    var data: Data { get }
    func toString() throws -> String
}
