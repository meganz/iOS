import MEGAL10n
import Search

extension SearchChipEntity {
    public static let images = SearchChipEntity(
        id: ChipId(MEGANodeFormatType.photo.rawValue),
        title: Strings.Localizable.Home.Search.Filter.images,
        icon: nil
    )
    public static let docs = SearchChipEntity(
        id: ChipId(MEGANodeFormatType.document.rawValue),
        title: Strings.Localizable.Home.Search.Filter.docs,
        icon: nil
    )
    public static let audio = SearchChipEntity(
        id: ChipId(MEGANodeFormatType.audio.rawValue),
        title: Strings.Localizable.Home.Search.Filter.audio,
        icon: nil
    )
    public static let video = SearchChipEntity(
        id: ChipId(MEGANodeFormatType.video.rawValue),
        title: Strings.Localizable.Home.Search.Filter.video,
        icon: nil
    )
    
    public static var allChips: [Self] {
        [
            .images,
            .docs,
            .audio,
            .video
        ]
    }
}
