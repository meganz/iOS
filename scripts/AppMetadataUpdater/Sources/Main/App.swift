import ArgumentParser
import Foundation

/// A command-line tool to update metadata (description, release notes, or all store metadata) on Weblate.
///
/// This tool accepts an authorization token and flags to determine which metadata should be updated.
/// - Flags:
///   - `--update-description`: Updates the description metadata only.
///   - `--update-release-notes`: Updates the release notes metadata.
///   - `--update-store-metadata`: Updates all store metadata (name, subtitle, keywords, promotional text, and description).
/// - Option:
///   - `-v` or `--version`: Specifies the version number for which the change logs need to be fetched (optional).
///
/// ### Examples
///
/// - **To update the app description:**
/// ```bash
/// $ swift run AppMetadataUpdater --update-description "Token 1/0ab1234567a91c2f341d5c678e9012c3b4567ed8"
/// ```
///
/// - **To update the release notes:**
/// ```bash
/// $ swift run AppMetadataUpdater --update-release-notes --version 16.1 "Token 1/0ab1234567a91c2f341d5c678e9012c3b4567ed8"
/// ```
///
/// - **To update all store metadata (name, subtitle, keywords, promotional text, description):**
/// ```bash
/// $ swift run AppMetadataUpdater --update-store-metadata "Token 1/0ab1234567a91c2f341d5c678e9012c3b4567ed8"
/// ```
///
/// - **To update store metadata and release notes:**
/// ```bash
/// $ swift run AppMetadataUpdater --update-store-metadata --update-release-notes --version 16.1 "Token 1/0ab1234567a91c2f341d5c678e9012c3b4567ed8"
/// ```
///
/// In these examples, the app will use the provided authorization token and update the relevant metadata on Weblate.
@main
struct App: AsyncParsableCommand {
    @Argument(help: "Authorization token for the Weblate. Example: 'Token 1/0ab1234567a91c2f341d5c678e9012c3b4567ed8'")
    var authorization: String

    @Flag(help: "Update the description metadata only.")
    var updateDescription = false

    @Flag(help: "Update the release notes metadata.")
    var updateReleaseNotes = false

    @Flag(help: "Update all store metadata (name, subtitle, keywords, promotional text, and description).")
    var updateStoreMetadata = false

    @Option(name: .shortAndLong, help: "version number for which the change logs needs to be fetched")
    var version: String? = nil

    func run() async throws {
        var metaDataUpdaters: [any MetadataUpdater] = []
        let environmentDetails = try EnvironmentDetails.load()

        if updateReleaseNotes {
            metaDataUpdaters.append(
                ReleaseNotesMetadataUpdater(
                    authorization: authorization,
                    version: version,
                    baseURL: environmentDetails.baseURL,
                    project: try project(for: .changelogs, from: environmentDetails)
                )
            )
        }

        if updateStoreMetadata {
            // --update-store-metadata writes all 5 files (name, subtitle, keywords,
            // promotional text, description) from a single fetch, so --update-description
            // is redundant when this flag is set.
            metaDataUpdaters.append(
                StoreMetadataUpdater(
                    authorization: authorization,
                    baseURL: environmentDetails.baseURL,
                    project: try project(for: .stores, from: environmentDetails)
                )
            )
        } else if updateDescription {
            metaDataUpdaters.append(
                DescriptionMetadataUpdater(
                    authorization: authorization,
                    baseURL: environmentDetails.baseURL,
                    project: try project(for: .stores, from: environmentDetails)
                )
            )
        }
        
        guard !metaDataUpdaters.isEmpty else { throw "Please pass in the flag while running the command" }
        try await updateMetadata(with: metaDataUpdaters)
    }

    private func project(
        for type: ComponentType,
        from environmentDetails: EnvironmentDetails
    ) throws -> Project {
        guard let project = environmentDetails[type] else {
            throw "project for \(type.rawValue) is not found"
        }

        return project
    }

    private func updateMetadata(with metaDataUpdaters: [any MetadataUpdater]) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for metadataUpdater in metaDataUpdaters {
                group.addTask {
                    try await metadataUpdater.updateMetadata()
                }
            }

            // Complete when the first task throws an error or wait until all tasks have finished successfully
            while let _ = try await group.next() {}
        }
    }
}

