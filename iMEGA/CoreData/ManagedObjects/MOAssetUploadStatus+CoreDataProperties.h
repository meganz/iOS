//
//  MOAssetUploadStatus+CoreDataProperties.h
//  
//
//  Created by Simon Wang on 5/10/18.
//
//

#import "MOAssetUploadStatus+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface MOAssetUploadStatus (CoreDataProperties)

+ (NSFetchRequest<MOAssetUploadStatus *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *localIdentifier;
@property (nullable, nonatomic, copy) NSString *statusCode;

@end

NS_ASSUME_NONNULL_END
