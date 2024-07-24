import MEGAL10n

final class HeaderViewModel: ObservableObject {
    private let isFile: Bool
    private let name: String
    
    init(isFile: Bool, name: String) {
        self.isFile = isFile
        self.name = name
    }
    
    var titleComponents: [String] {
        // Here we're using a UUID as a separator to "cut" the Strings.Localizable.NameCollision.Files.alreadyExists into 2 parts,
        // Then we re-construct the title components with `self.name` in the middle
        let separator = UUID().uuidString
        let stringComponents = (isFile ? Strings.Localizable.NameCollision.Files.alreadyExists(separator) : Strings.Localizable.NameCollision.Folders.alreadyExists(separator)).components(separatedBy: separator)
        
        return [stringComponents[safe: 0] ?? "", name, stringComponents[safe: 1] ?? ""]
    }
}
