import MessageKit

public protocol ChatViewMessagesLayoutDelegate: MessagesLayoutDelegate {
    func collectionView(_ collectionView: MessagesCollectionView, layout collectionViewLayout: MessagesCollectionViewFlowLayout, shouldEditItemAt indexPath: IndexPath) -> Bool
    
    func collectionView(_ collectionView: MessagesCollectionView, layout collectionViewLayout: MessagesCollectionViewFlowLayout, editingOffsetForCellAt indexPath: IndexPath) -> CGFloat
    
//    func collectionView(_ collectionView: MessagesCollectionView, editingOverlayAt indexPath: IndexPath, become selected:Bool)
    
}

class ChatViewMessagesFlowLayout: MessagesCollectionViewFlowLayout {
    lazy var chatViewCallCollectionCellCalculator = ChatViewCallCollectionCellCalculator(layout: self)
    lazy var chatViewAttachmentCellCalculator = ChatViewAttachmentCellCalculator(layout: self)
    lazy var chatMediaCollectionViewSizeCalculator = ChatMediaCollectionViewSizeCalculator(layout: self)
    lazy var chatRichPreviewMediaCollectionViewSizeCalculator = ChatRichPreviewMediaCollectionViewSizeCalculator(layout: self)
    lazy var chatContactLinkCollectionViewSizeCalculator = ChatContactLinkCollectionViewSizeCalculator(layout: self)
    lazy var chatVoiceClipCollectionViewSizeCalculator = ChatVoiceClipCollectionViewSizeCalculator(layout: self)
    lazy var chatLocationCollectionViewSizeCalculator = ChatlocationCollectionViewSizeCalculator(layout: self)
    lazy var chatGiphyCollectionViewSizeCalculator = ChatGiphyCollectionViewSizeCalculator(layout: self)
    lazy var chatManagementTypeCollectionViewSizeCalculator = ChatManagementTypeCollectionViewSizeCalculator(layout: self)
    lazy var chatAttributedTextMessageSizeCalculator  = ChatTextMessageSizeCalculator(layout: self)
    lazy var chatUnreadMessagesLabelCollectionCellSizeCalculator = ChatUnreadMessagesLabelCollectionCellSizeCalculator(layout: self)
    lazy var chatRichPreviewDialogCollectionViewSizeCalculator = ChatRichPreviewDialogCollectionViewSizeCalculator(layout: self)
    var editing = false {
        didSet {
            // setEditing changes the incoming avatar size, which changes every bubble's usable width.
            // The invalidateLayout() below carries neither invalidateEverything nor a width change
            // (see ChatViewMessagesFlowLayoutInvalidationTests), so the cache has to be dropped here.
            invalidateCachedSizes()
            invalidateLayout()
        }
    }
    
    /// Sizes already measured, keyed by message id and then by transfer state.
    ///
    /// MessageKit measures a message by assigning its attributed text to a real `MessageLabel` and
    /// calling `sizeThatFits`, which runs full typesetting; and reaching `ChatMessage.kind` on the
    /// way regenerates the attributed string as a side effect. UICollectionView re-runs
    /// `prepareLayout` for every item on any update, including a single-row `reloadItems`, so
    /// without this the cost of one attachment transfer event is the whole loaded history.
    ///
    /// Entries survive inserts and deletes because the outer key is the message id, not an index
    /// path. The inner key is everything else the height depends on: the transfer state, because an
    /// attachment's height can change as its transfer progresses and `attach(_:toMessageWithID:)`
    /// leaves the finished transfer on the message for good; and the two top-label heights, because
    /// the date and time labels are shown or hidden depending on the *previous* message, so a row's
    /// height changes when a sibling is inserted, deleted or prepended even though the row did not.
    /// Putting those heights in the key makes such a change a miss instead of a stale hit, with no
    /// index-path bookkeeping.
    ///
    /// Dropped again by `invalidateLayout(with:)` on `invalidateEverything` (which only
    /// `reloadData` sets), by `prepare(forCollectionViewUpdates:)` per reloaded row, by `editing`,
    /// and at lookup time when the width or content size category changed. It is not keyed on
    /// `invalidateFlowLayoutDelegateMetrics`: UIKit sets that on every row reload too, which would
    /// empty the cache on every transfer event. Measured in
    /// ChatViewMessagesFlowLayoutInvalidationTests.
    private var cachedSizes: [String: [ItemSizeKey: CGSize]] = [:]

    /// The inputs to an item's height other than the message itself. See `cachedSizes`.
    struct ItemSizeKey: Hashable {
        let transferState: Int
        let cellTopLabelHeight: CGFloat
        let messageTopLabelHeight: CGFloat
    }

    /// Message container sizes, same keys as `cachedSizes`. MessageKit measures the container
    /// twice per item: once through `sizeForItem` and again in `configure(attributes:)` while
    /// building layout attributes, and the second path never touches `sizeForItem`. The chat size
    /// calculators route their `messageContainerSize(for:at:)` through
    /// `cachedMessageContainerSize(for:at:measure:)` so both paths share one measurement.
    private var cachedContainerSizes: [String: [Int: CGSize]] = [:]
    private var cachedSizesWidth: CGFloat = 0
    private var cachedSizesContentSizeCategory: UIContentSizeCategory = .unspecified

    /// In-flight uploads are `ChatMessage(transfer:chatRoom:)` built on an empty `MEGAChatMessage`,
    /// so every one of them reports this same id. Computed from the real thing rather than assumed.
    private lazy var uploadPlaceholderMessageID = String(format: "%llu", MEGAChatMessage().messageId)

    /// Transfer-state slot for a message with no transfer.
    private static let noTransferState = -1

    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func sizeForItem(at indexPath: IndexPath) -> CGSize {
        guard let key = itemSizeKey(at: indexPath) else {
            return super.sizeForItem(at: indexPath)
        }

        discardCachedSizesIfEnvironmentChanged()

        if let cached = cachedSizes[key.messageID]?[key.itemKey] {
            return cached
        }

        let size = super.sizeForItem(at: indexPath)
        cachedSizes[key.messageID, default: [:]][key.itemKey] = size
        return size
    }

    /// The item-size key, or nil when the row must not be cached. Asks the layout delegate for the
    /// two neighbour-dependent label heights, the same calls MessageKit makes while sizing; they are
    /// a comparison with the previous message each, far cheaper than the measurement they guard.
    private func itemSizeKey(at indexPath: IndexPath) -> (messageID: String, itemKey: ItemSizeKey)? {
        guard !isSectionReservedForTypingIndicator(indexPath.section) else {
            return nil
        }

        let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView)
        guard let key = cacheKey(for: message) else {
            return nil
        }

        let delegate = messagesLayoutDelegate
        let itemKey = ItemSizeKey(
            transferState: key.transferState,
            cellTopLabelHeight: delegate.cellTopLabelHeight(for: message, at: indexPath, in: messagesCollectionView),
            messageTopLabelHeight: delegate.messageTopLabelHeight(for: message, at: indexPath, in: messagesCollectionView)
        )
        return (key.messageID, itemKey)
    }

    /// Nil for anything that must not be cached: the typing indicator, non-chat rows such as the
    /// unread separator, and upload placeholders (see `uploadPlaceholderMessageID`).
    private func cacheKey(at indexPath: IndexPath) -> (messageID: String, transferState: Int)? {
        guard !isSectionReservedForTypingIndicator(indexPath.section) else {
            return nil
        }

        return cacheKey(for: messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView))
    }

    private func cacheKey(for message: any MessageType) -> (messageID: String, transferState: Int)? {
        guard let chatMessage = message as? ChatMessage,
              chatMessage.messageId != uploadPlaceholderMessageID else {
            return nil
        }

        return (chatMessage.messageId, chatMessage.transfer?.state.rawValue ?? Self.noTransferState)
    }

    /// Returns the cached message container size for `message`, measuring it with `measure` on a
    /// miss. Called by every chat size calculator from `messageContainerSize(for:at:)`, which is
    /// where MessageKit lands from both `sizeForItem` and `configure(attributes:)`.
    func cachedMessageContainerSize(for message: any MessageType, at indexPath: IndexPath, measure: () -> CGSize) -> CGSize {
        guard let key = cacheKey(for: message) else {
            return measure()
        }

        discardCachedSizesIfEnvironmentChanged()

        if let cached = cachedContainerSizes[key.messageID]?[key.transferState] {
            return cached
        }

        let size = measure()
        cachedContainerSizes[key.messageID, default: [:]][key.transferState] = size
        return size
    }

    private func discardCachedSizesIfEnvironmentChanged() {
        let width = messagesCollectionView.bounds.width
        let contentSizeCategory = messagesCollectionView.traitCollection.preferredContentSizeCategory

        guard width != cachedSizesWidth || contentSizeCategory != cachedSizesContentSizeCategory else {
            return
        }

        invalidateCachedSizes()
        cachedSizesWidth = width
        cachedSizesContentSizeCategory = contentSizeCategory
    }

    /// Drops every cached size. Call whenever message contents may have changed wholesale.
    func invalidateCachedSizes() {
        cachedSizes.removeAll(keepingCapacity: true)
        cachedContainerSizes.removeAll(keepingCapacity: true)
    }

    override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        // Only reloadData sets invalidateEverything. Row reloads and a bare invalidateLayout() do
        // not, and both set invalidateFlowLayoutDelegateMetrics, which is why that flag is ignored.
        if context.invalidateEverything {
            invalidateCachedSizes()
        }

        super.invalidateLayout(with: context)
    }

    override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        // A reloaded row is a message whose contents changed in place. The data source already
        // holds the new state here, so the old key cannot be recomputed; drop every state for
        // that message. reloadSections arrives with item == NSNotFound, and messageForItem only
        // reads the section, so both row and section reloads land here.
        //
        // Inserts, deletes and moves need nothing: the only way a sibling change alters a row's
        // height is through the top-label heights, and those are part of the item key.
        for updateItem in updateItems where updateItem.updateAction == .reload {
            guard let indexPath = updateItem.indexPathAfterUpdate,
                  let key = cacheKey(at: indexPath) else {
                continue
            }

            cachedSizes.removeValue(forKey: key.messageID)
            cachedContainerSizes.removeValue(forKey: key.messageID)
        }

        super.prepare(forCollectionViewUpdates: updateItems)
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        guard let attributesArray = super.layoutAttributesForElements(in: rect), editing, let chatLayoutDelegate = messagesCollectionView.messagesLayoutDelegate as? (any ChatViewMessagesLayoutDelegate) else {
            return super.layoutAttributesForElements(in: rect)
        }
        
        var editingAttributesinRect: [UICollectionViewLayoutAttributes] = [UICollectionViewLayoutAttributes]()
        
        for attributes in attributesArray where attributes.representedElementCategory == .cell {
            if chatLayoutDelegate.collectionView(messagesCollectionView, layout: self, shouldEditItemAt: attributes.indexPath) {
                configureMessageCellLayoutAttributes(attributes)
                editingAttributesinRect.append(createEditingOverlayAttributesForCellAttributes(attributes))
            }
            
        }
        
        if editingAttributesinRect.isNotEmpty {
            return attributesArray + editingAttributesinRect
        } else {
            return attributesArray
        }

    }
    
    func configureMessageCellLayoutAttributes(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        guard let chatLayoutDelegate = messagesCollectionView.messagesLayoutDelegate as? (any ChatViewMessagesLayoutDelegate), chatLayoutDelegate.collectionView(messagesCollectionView, layout: self, shouldEditItemAt: layoutAttributes.indexPath) else {
            return
        }

        let offset = chatLayoutDelegate.collectionView(messagesCollectionView, layout: self, editingOffsetForCellAt: layoutAttributes.indexPath)
        layoutAttributes.frame = layoutAttributes.frame.offsetBy(dx: offset, dy: 0)

    }
    
    func createEditingOverlayAttributesForCellAttributes(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        
        let attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: "kCollectionElementKindEditOverlay", with: layoutAttributes.indexPath)
        attributes.zIndex = layoutAttributes.zIndex + 1
        
        let dataSource = messagesDataSource
        
        if !messagesCollectionView.isTypingIndicatorHidden && (layoutAttributes.indexPath.section == dataSource.numberOfSections(in: messagesCollectionView)) {
            attributes.frame = layoutAttributes.frame.offsetBy(dx: -50, dy: 0)
            return attributes
        }
        let message = dataSource.messageForItem(at: layoutAttributes.indexPath, in: messagesCollectionView)
        let isFromCurrentSender = dataSource.isFromCurrentSender(message: message)
        attributes.frame = layoutAttributes.frame.offsetBy(dx: isFromCurrentSender ? 0 : -50, dy: 0)

        return attributes
    }
    
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        switch elementKind {
        case "kCollectionElementKindEditOverlay":
            guard let itemAttributes = layoutAttributesForItem(at: indexPath) else {
                return super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)
            }
            return createEditingOverlayAttributesForCellAttributes(itemAttributes)
            
        default:
            break
        }
        return super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)
    }
     
    override func cellSizeCalculatorForItem(at indexPath: IndexPath) -> CellSizeCalculator {
        if isSectionReservedForTypingIndicator(indexPath.section) {
            return typingIndicatorSizeCalculator
        }
        let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView)

        if case .custom = message.kind {
            if message is ChatNotificationMessage {
                return chatUnreadMessagesLabelCollectionCellSizeCalculator
            }
            
            guard let chatMessage = message as? ChatMessage else {
                return super.cellSizeCalculatorForItem(at: indexPath)
            }
            
            switch chatMessage.message.type {
            case .attachment, .contact:
                if chatMessage.message.nodeList?.size ?? 0 == 1,
                   let node = chatMessage.message.nodeList?.node(at: 0),
                   node.name?.fileExtensionGroup.isVisualMedia ?? false {
                    return chatMediaCollectionViewSizeCalculator
                }
                return chatViewAttachmentCellCalculator
            case .callEnded, .callStarted:
                return chatViewCallCollectionCellCalculator
            case .normal:
                if chatMessage.message.warningDialog.rawValue > MEGAChatMessageWarningDialog.none.rawValue {
                    return chatRichPreviewDialogCollectionViewSizeCalculator
                } else if chatMessage.message.containsMEGALink() {
                    if (chatMessage.message.megaLink as? NSURL)?.mnz_type() == .contactLink {
                        return chatContactLinkCollectionViewSizeCalculator
                    }
                    return chatRichPreviewMediaCollectionViewSizeCalculator
                }
                return chatAttributedTextMessageSizeCalculator
            case .voiceClip:
                return chatVoiceClipCollectionViewSizeCalculator
            case .containsMeta:
                if chatMessage.message.containsMeta?.type == .geolocation {
                    return chatLocationCollectionViewSizeCalculator
                } else if chatMessage.message.containsMeta?.type == .giphy {
                   return chatGiphyCollectionViewSizeCalculator
                } else {
                    return chatRichPreviewMediaCollectionViewSizeCalculator
                }
            default:
                if chatMessage.message.isManagementMessage {
                    return chatManagementTypeCollectionViewSizeCalculator
                }
                if chatMessage.transfer?.transferChatMessageType() == .voiceClip {
                    return chatVoiceClipCollectionViewSizeCalculator
                }
                if chatMessage.transfer?.transferChatMessageType() == .attachment {
                    return chatMediaCollectionViewSizeCalculator
                }
                
                return super.cellSizeCalculatorForItem(at: indexPath)
            }
        }
        return super.cellSizeCalculatorForItem(at: indexPath)
    }
    
    override func messageSizeCalculators() -> [MessageSizeCalculator] {
        var calculators = super.messageSizeCalculators()
        calculators.append(contentsOf: [
            chatAttributedTextMessageSizeCalculator,
            chatViewAttachmentCellCalculator,
            chatMediaCollectionViewSizeCalculator,
            chatRichPreviewMediaCollectionViewSizeCalculator,
            chatContactLinkCollectionViewSizeCalculator,
            chatVoiceClipCollectionViewSizeCalculator,
            chatLocationCollectionViewSizeCalculator,
            chatGiphyCollectionViewSizeCalculator,
            chatManagementTypeCollectionViewSizeCalculator,
            chatRichPreviewDialogCollectionViewSizeCalculator
        ])
        return calculators
    }
    
}
