#import <Foundation/Foundation.h>

#import "LinkOption.h"
#import "URLType.h"

NS_ASSUME_NONNULL_BEGIN

@interface MEGALinkManager : NSObject

#pragma mark - Utils to manage MEGA links

@property (class, nonatomic, nullable) NSURL *linkURL;
@property (class, nonatomic, nullable) NSURL *secondaryLinkURL;
@property (class, nonatomic) URLType urlType;
@property (class, nonatomic, nullable) NSString *emailOfNewSignUpLink;

+ (void)resetLinkAndURLType;

#pragma mark - Utils to manage links when you are not logged

@property (class, nonatomic) LinkOption selectedOption;
@property (class, nonatomic, readonly) NSMutableArray *nodesFromLinkMutableArray;
@property (class, nonatomic) NSString *linkSavedString;

+ (void)resetUtilsForLinksWithoutSession;

+ (void)processSelectedOptionOnLink;

#pragma mark - Spotlight

@property (class, nonatomic) NSString *nodeToPresentBase64Handle;

+ (void)presentNode;

#pragma mark - Manage MEGA links

+ (NSString *)buildPublicLink:(NSString *)link withKey:(NSString *)key isFolder:(BOOL)isFolder;

+ (void)processLinkURL:( NSURL * _Nullable)url;

+ (void)showLinkNotValid;

+ (void)presentConfirmViewWithURLType:(URLType)urlType link:(NSString *)link email:(NSString *)email;

+ (void)showFileLinkView;

+ (void)handlePublicChatLink;

@property (class, nonatomic, readonly) NSMutableSet<NSString *> *joiningOrLeavingChatBase64Handles;

+ (void)createChatAndShow:(uint64_t)chatId publicChatLink:(NSURL *)publicChatLink;

+ (BOOL)isLoggedIn;

@end

NS_ASSUME_NONNULL_END
