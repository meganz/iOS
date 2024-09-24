import SharedReleaseScript

private let pathToTransifexScript = "./iosTransifex/iosTransifex.py"

func pruneTransifexStrings() throws {
    try runInShell("\(pathToTransifexScript) -m clean")
    try runInShell("\(pathToTransifexScript) -m clean -r lib")
    try runInShell("\(pathToTransifexScript) -m lang -r Localizable")
}

func downloadTransifexResources() throws {
    try runInShell("\(pathToTransifexScript) -m export")
}
