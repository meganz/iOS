//
//  AssetUploadOperation.m
//  MEGA
//
//  Created by Simon Wang on 10/10/18.
//  Copyright © 2018 MEGA. All rights reserved.
//

#import "AssetUploadOperation.h"

@interface AssetUploadOperation ()

@property (strong, nonatomic) NSString *assetLocalIdentifier;

@end

@implementation AssetUploadOperation

- (instancetype)initWithAssetLocalIdentifier:(NSString *)localIdentifier {
    self = [super init];
    if (self) {
        _assetLocalIdentifier = localIdentifier;
    }
    
    return self;
}

- (void)start {
    [super start];
    
    
}

@end
