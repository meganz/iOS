import Foundation
import SharedReleaseScript

func mergeMasterWithOursStrategyAndPushToOrigin() throws {
    try runInShell("git merge -s ours master")
    try runInShell("git push origin")
}
