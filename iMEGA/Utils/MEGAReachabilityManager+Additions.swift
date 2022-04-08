
extension MEGAReachabilityManager {
    static func statusConnectionMessage() -> String {
        if MEGAReachabilityManager.isReachable() {
            return MEGAReachabilityManager.isReachableViaWiFi() ? "WIFI" : "Mobile Data"
        }
        return "No internet connection"
    }
}
