import MEGASwift

public enum DependencyInjection {
    nonisolated(unsafe) private static var _appDomain: Atomic<String> = Atomic(wrappedValue: "mega.nz")

    public static var appDomain: String {
        get { _appDomain.wrappedValue }
        set { _appDomain.mutate { $0 = newValue } }
    }
}
