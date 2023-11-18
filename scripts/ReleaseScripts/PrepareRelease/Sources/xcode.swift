import SharedReleaseScript

func updateProjectVersion(_ newVersion: String) throws {
    let pathToPBXProj = "./MEGA.xcodeproj/project.pbxproj"
    let sedCommand = "sed -i '' 's/MARKETING_VERSION = [0-9]*\\.[0-9]*;/MARKETING_VERSION = \(newVersion);/' \(pathToPBXProj)"
    try runInShell(sedCommand)
}
