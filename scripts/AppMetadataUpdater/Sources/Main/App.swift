import ArgumentParser
import Foundation

import ArgumentParser
import Foundation

/// A command-line tool to update metadata (description or release notes) on Transifex.
///
/// This tool accepts an authorization token and flags to determine which metadata should be updated.
/// - Flags:
///   - `--update-description`: Updates the description metadata.
///   - `--update-release-notes`: Updates the release notes metadata.
/// - Option:
///   - `-v` or `--version`: Specifies the version number for which the change logs need to be fetched (optional).
///
/// ### Examples
///
/// - **To update the app description:**
/// ```bash
/// $ swift run AppMetadataUpdater --update-description "Bearer 1/0ab1234567a91c2f341d5c678e9012c3b4567ed8"
/// ```
///
/// - **To update the release notes:**
/// ```bash
/// $ swift run AppMetadataUpdater --update-release-notes --version 16.1 "Bearer 1/0ab1234567a91c2f341d5c678e9012c3b4567ed8"
/// ```
///
/// - **To update both description and release notes:**
/// ```bash
/// $ swift run AppMetadataUpdater --update-description --update-release-notes --version 16.1 "Bearer 1/0ab1234567a91c2f341d5c678e9012c3b4567ed8"
/// ```
///
/// In these examples, the app will use the provided authorization token and update the relevant metadata on Transifex.
@main
struct App: AsyncParsableCommand {
    @Argument(help: "Authorization token for the Transifex. Example: 'Bearer 1/0ab1234567a91c2f341d5c678e9012c3b4567ed8'")
    var authorization: String

    @Flag(help: "Update the description metadata.")
    var updateDescription = false

    @Flag(help: "Update the release notes metadata.")
    var updateReleaseNotes = false

    @Option(name: .shortAndLong, help: "version number for which the change logs needs to be fetched")
    var version: String? = nil

    func run() async throws {
        var metaDataUpdaters: [any MetadataUpdating] = []
        let environmentDetails = try EnvironmentDetails.load()

        if updateReleaseNotes {
            metaDataUpdaters.append(
                ReleaseNotesMetadataUpdater(
                    authorization: authorization,
                    version: version,
                    metadata: try metadata(for: .changelogs, from: environmentDetails)
                )
            )
        }

        if updateDescription {
            metaDataUpdaters.append(
                DescriptionMetadataUpdater(
                    authorization: authorization,
                    metadata: try metadata(for: .stores, from: environmentDetails)
                )
            )
        }
        
        guard !metaDataUpdaters.isEmpty else { throw "Please pass in the flag while running the command" }
        try await updateMetadata(with: metaDataUpdaters)
    }

    private func metadata(
        for resourceId: MetadataResourceId,
        from environmentDetails: EnvironmentDetails
    ) throws -> Metadata {
        guard let metadata = environmentDetails[resourceId] else {
            throw "metadata for \(resourceId.rawValue) is not found"
        }

        return metadata
    }

    private func updateMetadata(with metaDataUpdaters: [any MetadataUpdating]) async throws {
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

