import Foundation
import SwiftData

/// Builds the SwiftData container. On a load failure it reports the error and terminates the app.
enum ViewedLinksModelContainer {
    static func make(storeURL: URL?, inMemory: Bool) -> ModelContainer {
        let schema = Schema(versionedSchema: ViewedLinksSchemaV1.self)
        let configuration = makeConfiguration(storeURL: storeURL, inMemory: inMemory)
        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            if let reporter = DependencyInjection.errorReporting {
                reporter.reportFatalError(error)
            }
            fatalError("[ViewedLinks] Unrecoverable store: \(error)")
        }
    }

    private static func makeConfiguration(storeURL: URL?, inMemory: Bool) -> ModelConfiguration {
        if inMemory {
            return ModelConfiguration(isStoredInMemoryOnly: true)
        }
        let url = storeURL ?? URL.applicationSupportDirectory.appending(path: "ViewedLinks.store")
        return ModelConfiguration(url: url)
    }
}
