#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface MOOfflineNode : NSManagedObject

@property (nonnull, nonatomic, retain) NSString * base64Handle;
@property (nonnull, nonatomic, retain) NSString * localPath;
@property (nullable, nonatomic, retain) NSString * parentBase64Handle;
@property (nullable, nonatomic, retain) NSString * fingerprint;
@property (nullable, nonatomic, retain) NSDate * downloadedDate;

@end
