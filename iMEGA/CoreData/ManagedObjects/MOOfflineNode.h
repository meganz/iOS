#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface MOOfflineNode : NSManagedObject

@property (nonatomic, retain) NSString * base64Handle;
@property (nonatomic, retain) NSString * localPath;
@property (nonatomic, retain) NSString * parentBase64Handle;
@property (nonatomic, retain) NSString * fingerprint;

@end
