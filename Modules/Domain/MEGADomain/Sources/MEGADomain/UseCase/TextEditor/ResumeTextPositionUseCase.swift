import Foundation
import MEGAPreference

public protocol ResumeTextPositionUseCaseProtocol: Sendable {
    /// Saves the reading position of a text node as a character offset into its content.
    func saveReadingOffset(_ offset: Int, for node: NodeEntity)

    /// Retrieves the saved reading position of a text node, as a character offset.
    func readingOffset(for node: NodeEntity) -> Int?

    /// Deletes the saved reading position of a text node.
    func deleteReadingOffset(for node: NodeEntity)
}

private enum TextEditorPreferenceKeyEntity: PreferenceKeyProtocol {
    case textReadingOffsets

    var rawValue: String {
        switch self {
        case .textReadingOffsets: "textReadingOffsets"
        }
    }
}

public struct ResumeTextPositionUseCase: ResumeTextPositionUseCaseProtocol {
    @PreferenceWrapper(key: TextEditorPreferenceKeyEntity.textReadingOffsets, defaultValue: [:])
    private var textReadingOffsets: [String: Int]

    public init(preferenceUseCase: any PreferenceUseCaseProtocol) {
        $textReadingOffsets.useCase = preferenceUseCase
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
}
