enum DependencyInjection {
    static func compose() {
        composeSDKRepo()
        composeInfrastructure()
        composeLogger()
        composeAuthentication()
        composeAccountManagement()
    }
}
