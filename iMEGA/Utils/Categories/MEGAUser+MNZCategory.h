
#import "MEGAUser.h"

#import <Contacts/Contacts.h>

@interface MEGAUser (MNZCategory)

/**
 *  The concatenation of MEGA user firstname and lastname.
 * 
 * @note: If the contact has not firstname nor lastname or both are empty, this property is the user's email.
 *
 */
@property (nonatomic, readonly) NSString *mnz_fullName;

@property (nonatomic, readonly) NSString *mnz_firstName;

@property (nonatomic) NSString *mnz_nickname;

@property (nonatomic, readonly) NSString *mnz_displayName;

- (void)resetAvatarIfNeededInSdk:(MEGASdk *)sdk;
- (void)removeAvatarFromLocalCache;
+ (NSString *)mnz_fullName:(uint64_t)handle;

@end
