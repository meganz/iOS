#if DEBUG
extension ChangeTypeEntity: CustomDebugStringConvertible {
    static let allOptions: [Self] = [
        removed, attributes, owner, timestamp, fileAttributes, inShare, outShare, parent, pendingShare, publicLink, new, name, favourite, sensitive, tags, counter, pwd, description
    ]
    public var debugDescription: String {
        return switch rawValue {
        case Self.removed.rawValue: "remove"
        case Self.attributes.rawValue: "attributes"
        case Self.owner.rawValue: "owner"
        case Self.timestamp.rawValue: "timestamp"
        case Self.fileAttributes.rawValue: "fileAttributes"
        case Self.inShare.rawValue: "inShare"
        case Self.outShare.rawValue: "outShare"
        case Self.parent.rawValue: "parent"
        case Self.pendingShare.rawValue: "pendingShare"
        case Self.publicLink.rawValue: "publicLink"
        case Self.new.rawValue: "new"
        case Self.name.rawValue: "name"
        case Self.favourite.rawValue: "favourite"
        case Self.sensitive.rawValue: "sensitive"
        case Self.tags.rawValue: "tags"
        case Self.pwd.rawValue: "pwd"
        case Self.counter.rawValue: "counter"
        case Self.description.rawValue: "description"
        default:
            "\(individualValues)"
        }
    }
}

public extension ChangeTypeEntity {
    var individualValues: [ChangeTypeEntity] {
        var individualValues: [ChangeTypeEntity] = []

        // Iterate over all possible option values and check if they are present in the options
        let allOptions: [ChangeTypeEntity] = Self.allOptions

        for option in allOptions where self.contains(option) {
            individualValues.append(option)
        }

        return individualValues
    }

}
#endif
