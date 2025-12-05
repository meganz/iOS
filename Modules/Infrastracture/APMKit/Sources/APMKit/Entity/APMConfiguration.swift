struct APMConfiguration: Sendable {
    static var defaultConfig: APMConfiguration {
        APMConfiguration(hangConfig: APMHangConfiguration.defaultConfig)
    }
    let hangConfig: APMHangConfiguration?
}
