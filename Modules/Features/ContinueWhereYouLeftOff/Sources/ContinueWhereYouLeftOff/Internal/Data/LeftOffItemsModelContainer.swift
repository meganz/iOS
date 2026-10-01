import Foundation
import MEGAFoundation
import SwiftData

/// Builds the SwiftData container, falling back to memory when the store on disk cannot be opened.
enum LeftOffItemsModelContainer {
    static func make(storeURL: URL?, inMemory: Bool) -> ModelContainer {
        let schema = Schema(versionedSchema: LeftOffItemsSchemaV1.self)
        let configuration = makeConfiguration(storeURL: storeURL, inMemory: inMemory)
        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            MEGALog.log(level: .error, message: "[ContinueWhereYouLeftOff] Store failed to load: \(error)")
            return makeInMemory(schema: schema)
        }
    }

    private static func makeInMemory(schema: Schema) -> ModelContainer {
        do {
            return try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
        } catch {
            fatalError("[ContinueWhereYouLeftOff] Unrecoverable schema: \(error)")
        }
    }

    private static func makeConfiguration(storeURL: URL?, inMemory: Bool) -> ModelConfiguration {
        if inMemory {
            return ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        }
        let url = storeURL ?? URL.applicationSupportDirectory.appending(path: "ContinueWhereYouLeftOff.store")
        return ModelConfiguration(url: url, cloudKitDatabase: .none)
    }
}
