import Foundation

@objc protocol OverDiskQuotaInfomationProtocol {
    typealias Email = String
    typealias Deadline = Date
    typealias WarningDates = [Date]
    typealias FileCount = UInt
    typealias Storage = NSNumber
    typealias AvailablePlanName = String

    var email: Email { get }
    var deadline: Deadline { get }
    var warningDates: WarningDates { get }
    var numberOfFilesOnCloud: FileCount { get }
    var cloudStorage: Storage { get }
    var suggestedPlanName: AvailablePlanName? { get }
}

@objc final class OverDiskQuotaInformation: NSObject, OverDiskQuotaInfomationProtocol {
    let email: Email
    let deadline: Deadline
    let warningDates: WarningDates
    let numberOfFilesOnCloud: FileCount
    let cloudStorage: Storage
    let suggestedPlanName: AvailablePlanName?

    init(email: Email,
         deadline: Deadline,
         warningDates: WarningDates,
         numberOfFilesOnCloud: FileCount,
         cloudStorage: Storage,
         suggestedPlanName: AvailablePlanName?) {
        self.email = email
        self.deadline = deadline
        self.warningDates = warningDates
        self.numberOfFilesOnCloud = numberOfFilesOnCloud
        self.cloudStorage = cloudStorage
        self.suggestedPlanName = suggestedPlanName
    }
}
