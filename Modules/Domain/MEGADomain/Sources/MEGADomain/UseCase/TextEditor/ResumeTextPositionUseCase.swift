import Foundation
import MEGAPreference

public protocol ResumeTextPositionUseCaseProtocol: Sendable {
    /// Saves the reading position of a text node as a character offset into its content.
    func saveReadingOffset(_ offset: Int, for node: NodeEntity)

    /// Retrieves the saved reading position of a text node, as a character offset.
    func readingOffset(for node: NodeEntity) -> Int?

    /// Deletes the saved character offset of a text node.
    func deleteReadingOffset(for node: NodeEntity)

    /// Saves the reading position of a Markdown node as a 0-based source line.
    func saveReadingLine(_ line: Int, for node: NodeEntity)

    /// Retrieves the saved reading position of a Markdown node, as a 0-based source line.
    func readingLine(for node: NodeEntity) -> Int?

    /// Deletes the saved source line of a Markdown node.
    func deleteReadingLine(for node: NodeEntity)
}

private enum TextEditorPreferenceKeyEntity: PreferenceKeyProtocol {
    case textReadingOffsets
    case markdownReadingLines

    var rawValue: String {
        switch self {
        case .textReadingOffsets: "textReadingOffsets"
        case .markdownReadingLines: "markdownReadingLines"
        }
    }
}

public struct ResumeTextPositionUseCase: ResumeTextPositionUseCaseProtocol {
    @PreferenceWrapper(key: TextEditorPreferenceKeyEntity.textReadingOffsets, defaultValue: [:])
    private var textReadingOffsets: [String: Int]

    @PreferenceWrapper(key: TextEditorPreferenceKeyEntity.markdownReadingLines, defaultValue: [:])
    private var markdownReadingLines: [String: Int]

    public init(preferenceUseCase: any PreferenceUseCaseProtocol) {
        $textReadingOffsets.useCase = preferenceUseCase
        $markdownReadingLines.useCase = preferenceUseCase
    }

    public func saveReadingOffset(_ offset: Int, for node: NodeEntity) {
        guard let fingerprint = node.fingerprint else { return }
        textReadingOffsets[fingerprint] = offset
    }

    public func readingOffset(for node: NodeEntity) -> Int? {
        guard let fingerprint = node.fingerprint else { return nil }
        return textReadingOffsets[fingerprint]
    }

    public func deleteReadingOffset(for node: NodeEntity) {
        guard let fingerprint = node.fingerprint else { return }
        textReadingOffsets.removeValue(forKey: fingerprint)
    }

    public func saveReadingLine(_ line: Int, for node: NodeEntity) {
        guard let fingerprint = node.fingerprint else { return }
        markdownReadingLines[fingerprint] = line
    }

    public func readingLine(for node: NodeEntity) -> Int? {
        guard let fingerprint = node.fingerprint else { return nil }
        return markdownReadingLines[fingerprint]
    }

    public func deleteReadingLine(for node: NodeEntity) {
        guard let fingerprint = node.fingerprint else { return }
        markdownReadingLines.removeValue(forKey: fingerprint)
    }
}
