public struct RubbishBinSettingsEntity: Sendable {
    public let rubbishBinAutopurgePeriod: Int64
    public let rubbishBinCleaningSchedulerEnabled: Bool
    
    public init(rubbishBinAutopurgePeriod: Int64, rubbishBinCleaningSchedulerEnabled: Bool) {
        self.rubbishBinAutopurgePeriod = rubbishBinAutopurgePeriod
        self.rubbishBinCleaningSchedulerEnabled = rubbishBinCleaningSchedulerEnabled
    }
}
