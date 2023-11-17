/// represents a chip filter item
/// api currently supports the list of types you can use to filter is:
///
/// FILE_TYPE_PHOTO
/// FILE_TYPE_AUDIO
/// FILE_TYPE_VIDEO
/// FILE_TYPE_DOCUMENT
/// FILE_TYPE_PDF
/// FILE_TYPE_PRESENTATION
/// FILE_TYPE_ARCHIVE
/// FILE_TYPE_PROGRAM
/// FILE_TYPE_MISC
///
/// https://code.developers.mega.co.nz/sdk/sdk/-/blame/develop/include/megaapi.h?page=16#L15824

public struct SearchChipEntity: Equatable, Sendable {

    public let id: ChipId
    public let title: String
    public let icon: String?
    public let subchipsPickerTitle: String?
    public let subchips: [SearchChipEntity]

    public init(
        id: ChipId,
        title: String,
        icon: String? = nil,
        subchipsPickerTitle: String? = nil,
        subchips: [SearchChipEntity] = []
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.subchipsPickerTitle = subchipsPickerTitle
        self.subchips = subchips
    }
}

public typealias ChipId = Int

public extension ChipId {
    static var folder: Self { -1 }
    static var nodeType: Self { -2 }
}
