import Foundation
import MEGAFoundation
import Notifications

public extension NotificationItem {
    init(
        id: NotificationID = 1,
        title: String = "Test notification",
        description: String = "Test notification description",
        isSeen: Bool = Bool.random(),
        imageName: String? = nil,
        imagePath: String? = nil,
        iconName: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        redirectionURL: URL? = nil,
        formatDateClosure: @escaping DateFormatterClosure = { DateFormatter.dateLong().localisedString(from: $0) },
        formatTimeClosure: @escaping DateFormatterClosure = { DateFormatter.timeShort().localisedString(from: $0) },
        isTesting: Bool = true
    ) {
        self.init(
            id: id,
            title: title,
            description: description,
            isSeen: isSeen,
            imageName: imageName,
            imagePath: imagePath,
            iconName: iconName,
            startDate: startDate,
            endDate: endDate,
            redirectionURL: redirectionURL,
            formatDateClosure: formatDateClosure,
            formatTimeClosure: formatTimeClosure
        )
    }
}
