// Purpose of this structure is contains the result itself (a node)
// plus a method that can provide all other siblings
// present in the given search scope
// This is needed for example for:
// * select all functionality in the Cloud Drive
// * opening visual media (photo browser needs siblings of the selected photo to enable pagination in the gallery)
// * opening audio player (array of siblings is required to construct a
//   playlist of the audio files in the given folder)
public struct SearchResultSelection {
    
    public var result: SearchResult
    private var siblingsProvider: () -> [ResultId]
    
    public init(
        result: SearchResult,
        siblingsProvider: @escaping () -> [ResultId]
    ) {
        self.result = result
        self.siblingsProvider = siblingsProvider
    }
    
    public func siblings() -> [ResultId] {
        siblingsProvider()
    }
}
