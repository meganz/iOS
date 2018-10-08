//
//  MOAssetUploadRecord+CoreDataProperties.h
//  
//
//  Created by Simon Wang on 9/10/18.
//
//

#import "MOAssetUploadRecord+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface MOAssetUploadRecord (CoreDataProperties)

+ (NSFetchRequest<MOAssetUploadRecord *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *localIdentifier;
@property (nullable, nonatomic, copy) NSString *status;

@end

NS_ASSUME_NONNULL_END
