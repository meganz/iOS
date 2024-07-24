import MEGAFoundation
import MEGAL10n
import Search

extension SearchChipEntity {
    // MARK: - Node format chips
    public static let images = SearchChipEntity(
        type: .nodeFormat(.photo),
        title: Strings.Localizable.Home.Search.Filter.images
    )
    public static let folders = SearchChipEntity(
        type: .nodeType(.folder),
        title: Strings.Localizable.Home.Search.Filter.folders
    )
    public static let audio = SearchChipEntity(
        type: .nodeFormat(.audio),
        title: Strings.Localizable.Home.Search.Filter.audio
    )
    public static let video = SearchChipEntity(
        type: .nodeFormat(.video),
        title: Strings.Localizable.Home.Search.Filter.video
    )
    public static let pdf = SearchChipEntity(
        type: .nodeFormat(.pdf),
        title: Strings.Localizable.Home.Search.Filter.pdfs
    )
    public static let docs = SearchChipEntity(
        type: .nodeFormat(.document),
        title: Strings.Localizable.Home.Search.Filter.docs
    )
    public static let presentation = SearchChipEntity(
        type: .nodeFormat(.presentation),
        title: Strings.Localizable.Home.Search.Filter.presentations
    )
    public static let archives = SearchChipEntity(
        type: .nodeFormat(.archive),
        title: Strings.Localizable.Home.Search.Filter.archives
    )
    public static let spreadsheets = SearchChipEntity(
        type: .nodeFormat(.spreadsheet),
        title: Strings.Localizable.Home.Search.Filter.spreadsheets
    )

    // MARK: - Time filter by last modified time chips
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

    // MARK: - Grouped chips which have subchips which are displayed in the chips picker
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
        currentDate: @escaping () -> Date,
        calendar: Calendar
    ) -> [Self] {
        allChipsGrouped(
            currentDate: currentDate(),
            calendar: calendar
        )
    }
}
