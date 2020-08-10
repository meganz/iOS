#import "MOUser.h"

NS_ASSUME_NONNULL_BEGIN

@interface MOUser (CoreDataProperties)

@property (nonatomic, retain) NSString *base64userHandle;
@property (nullable, nonatomic, retain) NSString *firstname;
@property (nullable, nonatomic, retain) NSNumber *interactedwith;
@property (nullable, nonatomic, retain) NSString *lastname;
@property (nullable, nonatomic, retain) NSString *email;
@property (nullable, nonatomic, retain) NSString *nickname;

@end

NS_ASSUME_NONNULL_END
