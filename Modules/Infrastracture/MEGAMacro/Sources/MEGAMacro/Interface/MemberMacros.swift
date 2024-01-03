/// Add `newRepo`, `sdk` variables and `init(sdk:)` initializer.
///
///     @newRepo(MEGASDK.shared)
///     struct SampleRepo {}
///
///    will expand to
///
///     struct SampleRepo {
///         public static var newRepo: SampleRepo {
///             SampleRepo(sdk: MEGASDK.shared)
///         }
///         private let sdk: MEGASDK
///
///         public init(sdk:MEGASDK) { self.sdk = sdk }}
///     }
///
///     extension SampleRepo: RepositoryProtocol {}
@attached(member, names: named(newRepo), named(sdk), named(init(sdk:)))
public macro newRepo<T>(_ sdk: T) = #externalMacro(module: "MEGAMacroMacros", type: "NewRepoMacro")
