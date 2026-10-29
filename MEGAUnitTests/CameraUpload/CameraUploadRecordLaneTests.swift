@testable import MEGA
import Testing

/// Evaluates the lane predicates and ordering against sample records, so no Core Data is needed.
struct CameraUploadRecordLaneTests {
    private func record(errorPerLogin: Int? = nil, errorPerLaunch: Int? = nil, creationOffset: Double = 0) -> [String: Any] {
        var record: [String: Any] = ["creationDate": Date(timeIntervalSinceReferenceDate: creationOffset)]
        if let errorPerLogin {
            record["errorPerLogin"] = ["errorCount": NSNumber(value: errorPerLogin)]
        }
        if let errorPerLaunch {
            record["errorPerLaunch"] = ["errorCount": NSNumber(value: errorPerLaunch)]
        }
        return record
    }

    private func lanes(of record: [String: Any]) -> [String] {
        [
            ("never failed", CameraUploadRecordManager.neverFailedRecordsPredicate),
            ("failed before this launch", CameraUploadRecordManager.failedBeforeThisLaunchRecordsPredicate),
            ("failed in this launch", CameraUploadRecordManager.failedInThisLaunchRecordsPredicate)
        ].filter { $0.1.evaluate(with: record) }.map(\.0)
    }

    @Test func recordWithoutErrorsIsInNeverFailedLaneOnly() {
        #expect(lanes(of: record()) == ["never failed"])
    }

    @Test func recordThatFailedInEarlierLaunchIsInFailedBeforeThisLaunchLaneOnly() {
        #expect(lanes(of: record(errorPerLogin: 1)) == ["failed before this launch"])
    }

    @Test(arguments: [nil, 1])
    func recordThatFailedInThisLaunchIsInFailedInThisLaunchLaneOnly(errorPerLogin: Int?) {
        #expect(lanes(of: record(errorPerLogin: errorPerLogin, errorPerLaunch: 1)) == ["failed in this launch"])
    }

    @Test func failedInThisLaunchLaneServesLeastFailedFirstThenNewestFirst() {
        let records = [
            record(errorPerLaunch: 2, creationOffset: 30),
            record(errorPerLaunch: 1, creationOffset: 10),
            record(errorPerLaunch: 1, creationOffset: 20)
        ]

        let sorted = (records as NSArray).sortedArray(using: CameraUploadRecordManager.failedInThisLaunchRecordsSortDescriptors)
        let creationDates = sorted.compactMap { ($0 as? [String: Any])?["creationDate"] as? Date }
        #expect(creationDates == [20, 10, 30].map { Date(timeIntervalSinceReferenceDate: $0) })
    }
}
