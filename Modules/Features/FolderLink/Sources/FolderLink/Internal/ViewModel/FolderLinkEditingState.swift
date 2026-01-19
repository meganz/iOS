import MEGADomain

enum FolderLinkEditingState {
    case inactive
    case active(Set<HandleEntity>)
}
