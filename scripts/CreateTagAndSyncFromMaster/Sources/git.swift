import Foundation
import SharedReleaseScript

func mergeMasterWithOursStrategyAndPushToOrigin(currentBranch: String) throws {
    try runInShell("git fetch --all")
    try runInShell("git fetch origin")
    try runInShell("git checkout \(currentBranch)")
    try runInShell("git merge -s ours origin/master --gpg-sign")
    try runInShell("git push origin \(currentBranch)")
}
