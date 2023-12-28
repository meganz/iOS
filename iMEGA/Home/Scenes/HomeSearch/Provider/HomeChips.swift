import MEGAFoundation
import MEGAL10n
import Search

extension SearchChipEntity {
    // MARK: - Node format chipses
    public static let images = SearchChipEntity(
        type: .nodeFormat(MEGANodeFormatType.photo.rawValue),
        title: Strings.Localizable.Home.Search.Filter.images
    )
    public static let folders = SearchChipEntity(
        type: .nodeType(MEGANodeType.folder.rawValue),
        title: Strings.Localizable.Home.Search.Filter.folders
    )
    public static let audio = SearchChipEntity(
        type: .nodeFormat(MEGANodeFormatType.audio.rawValue),
        title: Strings.Localizable.Home.Search.Filter.audio
    )
    public static let video = SearchChipEntity(
        type: .nodeFormat(MEGANodeFormatType.video.rawValue),
        title: Strings.Localizable.Home.Search.Filter.video
    )
    public static let pdf = SearchChipEntity(
        type: .nodeFormat(MEGANodeFormatType.pdf.rawValue),
        title: Strings.Localizable.Home.Search.Filter.pdfs
    )
    public static let docs = SearchChipEntity(
        type: .nodeFormat(MEGANodeFormatType.document.rawValue),
        title: Strings.Localizable.Home.Search.Filter.docs
    )
    public static let presentation = SearchChipEntity(
        type: .nodeFormat(MEGANodeFormatType.presentation.rawValue),
        title: Strings.Localizable.Home.Search.Filter.presentations
    )
    public static let archives = SearchChipEntity(
        type: .nodeFormat(MEGANodeFormatType.archive.rawValue),
        title: Strings.Localizable.Home.Search.Filter.archives
    )
    public static let spreadsheets = SearchChipEntity(
        type: .nodeFormat(MEGANodeFormatType.spreadsheet.rawValue),
        title: Strings.Localizable.Home.Search.Filter.spreadsheets
    )

    // MARK: - Time filter by last modified time chipses
    private static func allTimeFilterChips(
        currentDate date: Date,
        calendar: Calendar
    ) -> [SearchChipEntity] {
        [
            today(calendar: calendar, currentDate: date),
            last7Days(calendar: calendar, currentDate: date),
            last30Days(calendar: calendar, currentDate: date),
            thisYear(calendar: calendar, currentDate: date),
            lastYear(currentDate: date),
            older(currentDate: date)
        ]
    }

    public static func today(
        calendar: Calendar,
        currentDate date: Date
    ) -> SearchChipEntity {
        SearchChipEntity(
            type: .timeFrame(
                .init(
                    startDate: calendar.startOfDay(for: date),
                    endDate: date.endOfDay(calendar: calendar) ?? date
                )
            ),
            title: Strings.Localizable.Home.Search.Filter.ModificationDate.today
        )
    }

    public static func last7Days(
        calendar: Calendar,
        currentDate date: Date
    ) -> SearchChipEntity {
        SearchChipEntity(
            type: .timeFrame(
                .init(
                    startDate: date.daysAgo(7) ?? Date(),
                    endDate: date.endOfDay(calendar: calendar) ?? date
                )
            ),
            title: Strings.Localizable.Home.Search.Filter.ModificationDate.last7days
        )
    }

    public static func last30Days(
        calendar: Calendar,
        currentDate date: Date
    ) -> SearchChipEntity {
        SearchChipEntity(
            type: .timeFrame(
                .init(
                    startDate: date.daysAgo(30) ?? Date(),
                    endDate: date.endOfDay(calendar: calendar) ?? date
                )
            ),
            title: Strings.Localizable.Home.Search.Filter.ModificationDate.last30days
        )
    }

    public static func thisYear(
        calendar: Calendar,
        currentDate date: Date
    ) -> SearchChipEntity {
        SearchChipEntity(
            type: .timeFrame(
                .init(
                    startDate: date.currentYearStartDate() ?? Date(),
                    endDate: date.endOfDay(calendar: calendar) ?? date
                )
            ),
            title: Strings.Localizable.Home.Search.Filter.ModificationDate.thisYear
        )
    }

    public static func lastYear(currentDate date: Date) -> SearchChipEntity {
        SearchChipEntity(
            type: .timeFrame(
                .init(
                    startDate: date.previousYearStartDate() ?? Date(),
                    endDate: date.currentYearStartDate() ?? Date()
                )
            ),
            title: Strings.Localizable.Home.Search.Filter.ModificationDate.lastYear
        )
    }

    public static func older(currentDate date: Date) -> SearchChipEntity {
        SearchChipEntity(
            type: .timeFrame(
                .init(
                    startDate: Date.distantPast,
                    endDate: date.previousYearStartDate() ?? Date()
                )
            ),
            title: Strings.Localizable.Home.Search.Filter.ModificationDate.older
        )
    }

    // MARK: - Grouped chipses which have subchipses which are displayed in the chips picker
    public static let nodeFormatsGroupedChip = SearchChipEntity(
        type: .Grouped,
        title: Strings.Localizable.Home.Search.ChipsGroup.NodeType.pillTitle,
        subchipsPickerTitle: Strings.Localizable.Home.Search.ChipsGroup.NodeType.pickerTitle,
        subchips: allNodeFormatChips
    )

    private static var allNodeFormatChips: [Self] {
        [
            .images,
            .audio,
            .video,
            .folders,
            .pdf,
            .docs,
            .presentation,
            .archives,
            .spreadsheets
        ]
    }

    private static func timeFilterGroupedChip(
        currentDate: Date,
        calendar: Calendar
    ) -> SearchChipEntity {
        SearchChipEntity(
            type: .Grouped,
            title: Strings.Localizable.Home.Search.ChipsGroup.ModificationDate.pillTitle,
            subchipsPickerTitle: Strings.Localizable.Home.Search.ChipsGroup.ModificationDate.pickerTitle,
            subchips: allTimeFilterChips(
                currentDate: currentDate,
                calendar: calendar
            )
        )
    }

    private static func allChipsGrouped(
        currentDate: Date,
        calendar: Calendar
    ) -> [SearchChipEntity] {
        [
            nodeFormatsGroupedChip,
            timeFilterGroupedChip(
                currentDate: currentDate,
                calendar: calendar
            )
        ]
    }

    public static func allChips(
        areChipsGroupEnabled: Bool,
        currentDate: @escaping () -> Date,
        calendar: Calendar
    ) -> [Self] {
        let allChipsGrouped = allChipsGrouped(
            currentDate: currentDate(),
            calendar: calendar
        )
        return areChipsGroupEnabled ? allChipsGrouped : allNodeFormatChips
    }
}

extension SearchQueryEntity {
    var searchFilter: MEGASearchFilter {
        let filter = MEGASearchFilter()

        filter.term = query

        if let firstNodeTypeChip = chips.first(where: { $0.type.isNodeTypeChip })?.type,
           case let SearchChipEntity.ChipType.nodeType(nodeType) = firstNodeTypeChip {
            filter.nodeType = Int32(nodeType)
        }

        if let firstNodeFormatChip = chips.first(where: { $0.type.isNodeFormatChip })?.type,
           case let SearchChipEntity.ChipType.nodeFormat(nodeFormat) = firstNodeFormatChip {
            filter.category = Int32(nodeFormat)
        }

        // SDK support both creation and modification date
        // but we only support modification date
        if let firstTimeFilterChip = chips.first(where: { $0.type.isTimeFilterChip })?.type,
           case let SearchChipEntity.ChipType.timeFrame(timeFrame) = firstTimeFilterChip {
            filter.modificationTimeFrame = .init(
                lowerLimit: timeFrame.startDate,
                upperLimit: timeFrame.endDate
            )
        }

        return filter
    }
}
