/// represents a chip filter item
/// api currently supports the list of types you can use to filter is:
/// 1. Filter by node format type
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
/// 2. Filter by modification date time frame
/// Today
/// Last 7 days
/// Last 30 days
/// This year
/// Last year
/// Older
///
/// 3. Filter by node type (used for folder chips filtering)
///
/// https://code.developers.mega.co.nz/sdk/sdk/-/blame/develop/include/megaapi.h?page=16#L15824

import UIKit

public struct SearchChipEntity: Equatable, Sendable {
    public struct TimeFrame: Equatable, Sendable {
        public let startDate: Date
        public let endDate: Date

        public init(startDate: Date, endDate: Date) {
            self.startDate = startDate
            self.endDate = endDate
        }
    }
    
    public enum NodeType: Sendable {
        case unknown
        case file
        case folder
        case root
        case incoming
        case rubbish
    }
    
    public enum NodeFormat: Sendable {
        case unknown
        case photo
        case audio
        case video
        case document
        case pdf
        case presentation
        case archive
        case program
        case misc
        case spreadsheet
        case allDocs
    }

    public enum ChipType: Equatable, Sendable {
        case Grouped
        case nodeFormat(NodeFormat)
        case nodeType(NodeType)
        case timeFrame(TimeFrame)

        public var isNodeFormatChip: Bool {
            switch self {
            case .nodeFormat:
                return true
            default:
                return false
            }
        }

        public var isNodeTypeChip: Bool {
            switch self {
            case .nodeType:
                return true
            default:
                return false
            }
        }

        public var isTimeFilterChip: Bool {
            switch self {
            case .timeFrame:
                return true
            default:
                return false
            }
        }

        public func isInSameChipGroup(as chipType: ChipType) -> Bool {
            switch (self, chipType) {
            case (.Grouped, .Grouped),
                (.nodeFormat, .nodeFormat),
                (.nodeType, .nodeType),
                (.timeFrame, .timeFrame):
              return true
            default:
                // nodeType chip and nodeFormat chip are displayed in the same chip group
                return self.isNodeTypeChip && chipType.isNodeFormatChip
                    || self.isNodeFormatChip && chipType.isNodeTypeChip
            }
        }
    }

    public var id: String { title }
    public let type: ChipType
    public let title: String
    public let icon: String?
    public let subchipsPickerTitle: String?
    public let subchips: [SearchChipEntity]

    public init(
        type: ChipType,
        title: String,
        icon: String? = nil,
        subchipsPickerTitle: String? = nil,
        subchips: [SearchChipEntity] = []
    ) {
        self.type = type
        self.title = title
        self.icon = icon
        self.subchipsPickerTitle = subchipsPickerTitle
        self.subchips = subchips
    }
}
