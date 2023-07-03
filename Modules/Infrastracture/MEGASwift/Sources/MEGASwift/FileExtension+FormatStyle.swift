import Foundation

public enum CapitalizationStrategy: Codable, Hashable {
    case verbatim    // "whatever THEY proVide"
    case lowercased  // "lower case"
    case uppercase   // "UPPER CASE"
    case capitalized // "Capitalized Case"
}

// MARK: - File Extension Components Style

protocol FilePathComponentStylable: Codable, Hashable {
    associatedtype FormatInput: Codable, Hashable
    associatedtype FormatOutput: Codable, Hashable
    
    var capitalization: CapitalizationStrategy { get }
    var allowedCharacters: CharacterSet? { get }
    var locale: Locale { get }
    
    init(capitalization: CapitalizationStrategy, removingCharactersIn forbiddenCharacters: CharacterSet?, locale: Locale)
    
    func remove(charactersIn set: CharacterSet) -> Self
    func capitalization(_ strategy: CapitalizationStrategy) -> Self
    
    func format(_ input: FormatInput) -> FormatOutput
}

extension FilePathComponentStylable where FormatInput == String, FormatOutput == String {
    func format(_ input: FormatInput) -> FormatOutput {
        var result = ""
        switch capitalization {
        case .verbatim: result = input
        case .lowercased: result = input.lowercased()
        case .uppercase: result = input.uppercased()
        case .capitalized: result = input.capitalized(with: locale)
        }
        guard let allowedCharacters else { return result }
        let unicodeScalars = String.UnicodeScalarView(result.unicodeScalars.filter(allowedCharacters.contains(_:)))
        return String(unicodeScalars)

    }
}

// MARK: - File Extension Style

protocol FilePathStylable: Codable, Hashable {
    associatedtype FormatInput: Codable, Hashable
    associatedtype FormatOutput: Codable, Hashable
    associatedtype ComponentNameStyle: FilePathComponentStylable where ComponentNameStyle.FormatInput == FormatInput
    associatedtype ComponentExtensionStyle: FilePathComponentStylable where ComponentExtensionStyle.FormatInput == FormatInput
    
    var locale: Locale { get }
    var nameStyle: ComponentNameStyle? { get }
    var pathExtensionStyle: ComponentExtensionStyle? { get }
    
    init(name style: ComponentNameStyle?, extensionStyle: ComponentExtensionStyle?, locale: Locale)
    
    func name(capitalization: CapitalizationStrategy, removingCharactersIn forbiddenCharacters: CharacterSet?) -> Self
    func pathExtension(capitalization: CapitalizationStrategy, removingCharactersIn forbiddenCharacters: CharacterSet?) -> Self
    
    func format(_ input: FormatInput) -> FormatOutput
}

extension FilePathStylable where FormatInput == FileExtension, FormatOutput == String {
    func name(capitalization: CapitalizationStrategy = .verbatim, removingCharactersIn forbiddenCharacters: CharacterSet? = nil) -> Self {
        .init(
            name: .init(capitalization: capitalization, removingCharactersIn: forbiddenCharacters, locale: locale),
            extensionStyle: pathExtensionStyle,
            locale: locale
        )
    }
    
    func pathExtension(capitalization: CapitalizationStrategy = .verbatim, removingCharactersIn forbiddenCharacters: CharacterSet? = nil) -> Self {
        .init(
            name: nameStyle,
            extensionStyle: .init(capitalization: capitalization, removingCharactersIn: forbiddenCharacters, locale: locale),
            locale: locale
        )
    }
}

// MARK: - File Extension Format Style Implementation
extension FileExtension {
    
    struct FormatStyle: FilePathStylable {
        typealias FormatInput = FileExtension
        typealias FormatOutput = String
        
        typealias ComponentNameStyle = FileExtension.Component.FormatStyle<FormatInput, FormatOutput>
        typealias ComponentExtensionStyle = FileExtension.Component.FormatStyle<FormatInput, FormatOutput>
        
        let nameStyle: ComponentNameStyle?
        let pathExtensionStyle: ComponentExtensionStyle?
        let locale: Locale
        
        init(name style: ComponentNameStyle? = .verbatim, extensionStyle: ComponentExtensionStyle? = .verbatim, locale: Locale = .autoupdatingCurrent) {
            nameStyle = style
            pathExtensionStyle = extensionStyle
            self.locale = locale
        }
        
        func format(_ input: FormatInput) -> FormatOutput {
            let components = fileNameComponents(for: input)
            var resultElements = [String]()
            
            if let nameStyle, let fileName = components.fileName {
                resultElements.append(nameStyle.format(fileName))
            }
            
            if let pathExtensionStyle, let fileExtension = components.fileExtension {
                resultElements.append(pathExtensionStyle.format(fileExtension))
            }
            
            return resultElements.joined(separator: ".")
        }
        
        // MARK: Private methods
        private func fileNameComponents(for fileExtension: FileExtension) -> (fileName: String?, fileExtension: String?) {
            var components = fileExtension.split(separator: ".")
            var fileExtension: String?
            if components.count > 1 {
                fileExtension = String(components.removeLast())
            }
            return (fileName: components.joined(separator: "."), fileExtension: fileExtension)
        }
    }
    
    enum Component {
        struct FormatStyle<FormatInput, FormatOutput>: FilePathComponentStylable {
            typealias FormatInput = String
            typealias FormatOutput = String
            
            static var verbatim: Self { .init() }
            
            let capitalization: CapitalizationStrategy
            let allowedCharacters: CharacterSet?
            let locale: Locale
            
            init(capitalization: CapitalizationStrategy = .verbatim, removingCharactersIn forbiddenCharacters: CharacterSet? = nil, locale: Locale = .autoupdatingCurrent) {
                self.capitalization = capitalization
                self.locale = locale
                allowedCharacters = forbiddenCharacters?.inverted
            }
            
            func capitalization(_ strategy: CapitalizationStrategy) -> Self {
                .init(capitalization: strategy, removingCharactersIn: allowedCharacters?.inverted, locale: self.locale)
            }
            
            func remove(charactersIn set: CharacterSet) -> Self {
                .init(capitalization: capitalization, removingCharactersIn: set, locale: self.locale)
            }
        }
    }
}

@available(iOS 15.0, *)
extension FileExtension {
    func formatted<F: Foundation.FormatStyle>(_ style: F) -> F.FormatOutput where F.FormatInput == Self {
        style.format(self)
    }
}

@available(iOS 15.0, *)
extension FileExtension.Component {
    func formatted<F: Foundation.FormatStyle>(_ style: F) -> F.FormatOutput where F.FormatInput == Self {
        style.format(self)
    }
}

@available(iOS 15.0, *)
extension FileExtension.FormatStyle: Foundation.FormatStyle {
    func locale(_ locale: Locale) -> Self {
        .init(name: nameStyle, extensionStyle: pathExtensionStyle, locale: locale)
    }
}

@available(iOS 15.0, *)
extension FileExtension.Component.FormatStyle: Foundation.FormatStyle where FormatInput == String, FormatOutput == String {
    static func component(capitalization: CapitalizationStrategy = .verbatim, removingCharactersIn forbiddenCharacters: CharacterSet? = nil, locale: Locale = .autoupdatingCurrent) -> Self {
        .init(capitalization: capitalization, removingCharactersIn: forbiddenCharacters, locale: locale)
    }
}

@available(iOS 15.0, *)
extension FormatStyle where Self == FileExtension.FormatStyle {
    
    static func filePath(name style: Self.ComponentNameStyle? = .verbatim, extensionStyle: Self.ComponentExtensionStyle? = .verbatim, locale: Locale = .autoupdatingCurrent) -> Self {
        .init(name: style, extensionStyle: extensionStyle, locale: locale)
    }
}
