import Foundation
import SharedReleaseScript

setVerbose()

do {
    log("Started execution")
    let input = try releaseInput()
    
    let releaseBranch = "release/\(input.version)"
    
    log("Checking out to release branch and pull")
    try checkoutToReleaseAndPull(releaseBranch)
    
    log("Merging \(releaseBranch) into master")
    try await mergeReleaseMR(input.version)
    
    log("Creating release in Gitlab")
    try await createRelease(input)
    
    log("Marking version \(input.version) as released in Jira projects")
    try await markCurrentVersionAsReleasedInAllProjects(version: input.version)
    
    log("Pushing master to GitHub")
    try pushToPublicMaster(input.version)
    
    log("Finished successfully")
    exit(ProcessResult.success)
} catch {
    exitWithError(error)
}

private func log(_ message: String) {
    print("MergeRelease script - \(message)")
}
