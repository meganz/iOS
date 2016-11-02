#import "MEGAMessage.h"

@implementation MEGAMessage

#pragma mark - Initialization

- (instancetype)initWithMEGAChatMessage:(MEGAChatMessage *)message {
    NSParameterAssert(message != nil);
    self = [super init];
    if (self) {
        _userHandle        = message.userHande;
        _messageId         = message.messageId;
        _senderId          = [NSString stringWithFormat:@"%llu", message.userHande];
        _date              = message.timestamp;
        _index             = message.messageIndex;
        _editable          = message.isEditable;
        _edited            = message.isEdited;
        _deleted           = message.isDeleted;
        if (message.isDeleted) {
            _text = @"This message has been deleted";
        } else {
            _text = message.content;
        }
        
    }
    return self;
}

- (NSUInteger)messageHash {
    return self.hash;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    
    MEGAMessage *aMessage = (MEGAMessage *)object;
    
    if (self.isMediaMessage != aMessage.isMediaMessage) {
        return NO;
    }
    
    BOOL hasEqualContent = self.isMediaMessage ? [self.media isEqual:aMessage.media] : [self.text isEqualToString:aMessage.text];
    
    return [self.senderId isEqualToString:aMessage.senderId]
    && [self.senderDisplayName isEqualToString:aMessage.senderDisplayName]
    && ([self.date compare:aMessage.date] == NSOrderedSame)
    && hasEqualContent;
}

- (NSUInteger)hash {
    NSUInteger contentHash = self.isMediaMessage ? [self.media mediaHash] : self.text.hash;
    return self.senderId.hash ^ self.date.hash ^ contentHash;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: senderId=%@, date=%@, isMediaMessage=%@, text=%@, media=%@, index=%ld>",
            [self class], self.senderId, self.date, @(self.isMediaMessage), self.text, self.media, (long)self.index];
}

- (id)debugQuickLookObject {
    return [self.media mediaView] ?: [self.media mediaPlaceholderView];
}

@end
