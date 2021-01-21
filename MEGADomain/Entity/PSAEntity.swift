typealias PSAIdentifier = Int

struct PSAEntity {
    let identifier: PSAIdentifier
    let title: String
    let description: String
    let imageURL: String?
    let positiveText: String?
    let positiveLink: String?
    let URLString: String?
}

extension PSAEntity: Equatable {
    static func ==(lhs: PSAEntity, rhs: PSAEntity) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}
