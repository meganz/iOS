#import "MEGATransfer+MNZCategory.h"
#import "Helper.h"
#import "MEGANode+MNZCategory.h"
#import "NSFileManager+MNZCategory.h"
#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#else
#import "MEGA-Swift.h"
#endif

@implementation MEGATransfer (MNZCategory)

#pragma mark - App data

- (MEGAChatMessageType)transferChatMessageType {
    if ([self.appData containsString:@"attachToChatID"]) {
        return MEGAChatMessageTypeAttachment;
    }
    
    if ([self.appData containsString:@"attachVoiceClipToChatID"]) {
         return MEGAChatMessageTypeVoiceClip;
    }
    
    return MEGAChatMessageTypeUnknown;
}

- (NSArray *)appDataComponents {
    if (!self.appData) {
        return nil;
    }
    
    return [self.appData componentsSeparatedByString:@">"];
}

- (void)enumerateAppDataTypeWithBlock:(void (^)(NSString *, NSString *))block {
    NSArray *appDataComponentsArray = self.appDataComponents;
      if (self.appDataComponents.count) {
          for (NSString *appDataComponent in appDataComponentsArray) {
              NSArray *appDataComponentComponentsArray = [appDataComponent componentsSeparatedByString:@"="];
              NSString *appDataType = appDataComponentComponentsArray.firstObject;
              block(appDataType, appDataComponent);
          }
      }
}

- (void)mnz_parseChatAttachmentAppData {
    [self enumerateAppDataTypeWithBlock:^(NSString * appDataType, NSString *appDataComponent) {
        
        if ([appDataType isEqualToString:@"attachToChatID"]) {
            NSString *tempAppDataComponent = [appDataComponent stringByReplacingOccurrencesOfString:@"!" withString:@""];
            [self mnz_attachtToChatID:tempAppDataComponent asVoiceClip:NO];
        }
        
        if ([appDataType isEqualToString:@"attachVoiceClipToChatID"]) {
            NSString *tempAppDataComponent = [appDataComponent stringByReplacingOccurrencesOfString:@"!" withString:@""];
            [self mnz_moveFileToDestinationIfVoiceClipData];
            [self mnz_attachtToChatID:tempAppDataComponent asVoiceClip:YES];
        }
        
    }];
}

- (void)mnz_attachtToChatID:(NSString *)attachToChatID asVoiceClip:(BOOL)asVoiceClip {
    NSArray *appDataComponentComponentsArray = [attachToChatID componentsSeparatedByString:@"="];
    NSString *chatID = [appDataComponentComponentsArray objectAtIndex:1];
    unsigned long long chatIdUll = strtoull(chatID.UTF8String, NULL, 0);
    if (asVoiceClip) {
        [MEGAChatSdk.shared attachVoiceMessageToChat:chatIdUll node:self.nodeHandle];
    } else {
        [MEGAChatSdk.shared attachNodeToChat:chatIdUll node:self.nodeHandle];
    }
}

- (NSString *)mnz_extractChatIDFromAppData {
    __block NSString *chatID;
    
    [self enumerateAppDataTypeWithBlock:^(NSString * appDataType, NSString *appDataComponent) {
         
         if ([appDataType isEqualToString:@"attachToChatID"] || [appDataType isEqualToString:@"attachVoiceClipToChatID"]) {
             NSString *tempAppDataComponent = [appDataComponent stringByReplacingOccurrencesOfString:@"!" withString:@""];
             chatID = [tempAppDataComponent componentsSeparatedByString:@"="].lastObject;
         }
     }];
    
    return chatID;
}

- (NSString *)mnz_extractMessageIDFromAppData {
    __block NSString *messageID;
    
    [self enumerateAppDataTypeWithBlock:^(NSString * appDataType, NSString *appDataComponent) {
         
         if ([appDataType isEqualToString:@"downloadAttachToMessageID"]) {
             NSString *tempAppDataComponent = [appDataComponent stringByReplacingOccurrencesOfString:@"!" withString:@""];
             messageID = [tempAppDataComponent componentsSeparatedByString:@"="].lastObject;
         }
     }];
    
    return messageID;
}

- (void)mnz_moveFileToDestinationIfVoiceClipData {
    if ([self.appData containsString:@"attachVoiceClipToChatID"]) {
        MEGANode *node = [MEGASdk.shared nodeForHandle:self.nodeHandle];
        if (node) {
            NSString *nodeFilePath = [node mnz_voiceCachePath];
            [NSFileManager.defaultManager mnz_moveItemAtPath:self.path toPath:nodeFilePath];
        }
    }
}

- (NSUInteger)mnz_orderByState {
    NSUInteger orderByState;
    
    switch (self.state) {
        case MEGATransferStateCompleting:
            orderByState = 0;
            break;
            
        case MEGATransferStateActive:
            orderByState = 1;
            break;
            
        case MEGATransferStateQueued:
            orderByState = 2;
            break;
            
        default:
            orderByState = 3;
            break;
    }
    
    return orderByState;
}

- (MEGANode *)node {
    MEGANode *node;
    if (self.publicNode) {
        node = self.publicNode;
    } else {
        node = [MEGASdk.shared nodeForHandle:self.nodeHandle];
    }
    return node;
}

- (void)mnz_setCoordinates:(NSString *)coordinates {
    NSArray *setCoordinatesComponentsArray = [coordinates componentsSeparatedByString:@"&"];
    if (setCoordinatesComponentsArray.count == 2) {
        NSString *latitude = setCoordinatesComponentsArray.firstObject;
        NSString *longitude = [setCoordinatesComponentsArray objectAtIndex:1];
        if (latitude && longitude) {
            MEGANode *node = [MEGASdk.shared nodeForHandle:self.nodeHandle];
            [MEGASdk.shared setUnshareableNodeCoordinates:node latitude:latitude.doubleValue longitude:longitude.doubleValue];
        }
    }
}

@end
