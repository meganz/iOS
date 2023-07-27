import Foundation

struct ChatRoomAvatarInitialsGenerator {
    static func generateInitials(from name: String) -> String {
        let prefixTwoComponents = name
            .components(separatedBy: " ")
            .filter {$0.count > 0}
            .prefix(2)
        
        let initials: String
        switch prefixTwoComponents.count {
        case 1:
            initials = prefixTwoComponents
                .compactMap({ $0.count >= 1 ? String($0.prefix(1)).uppercased() : nil })
                .joined(separator: "")
        case 2:
            let first = prefixTwoComponents[0]
            let second = prefixTwoComponents[1]
            if (first.count == 1 && second.count == 1) ||
                (first.count > 1 && second.count > 1) {
                initials = prefixTwoComponents
                    .compactMap({ $0.count >= 1 ? String($0.prefix(1)).uppercased() : nil })
                    .joined(separator: "")
            } else {
                initials = prefixTwoComponents
                    .compactMap({ $0.count > 1 ? String($0.prefix(1)).uppercased() : nil })
                    .joined(separator: "")
            }
        default:
            initials = "CC"
        }
        return initials
    }
}
