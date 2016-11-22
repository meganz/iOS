#import "MEGAChatListItemList.h"
#import "megachatapi.h"
#import "MEGAChatListItem+init.h"

using namespace megachat;

@interface MEGAChatListItemList ()

@property MegaChatListItemList *megaChatListItemList;
@property BOOL cMemoryOwn;

@end

@implementation MEGAChatListItemList

- (instancetype)initWithMegaChatListItemList:(MegaChatListItemList *)megaChatListItemList cMemoryOwn:(BOOL)cMemoryOwn {
    self = [super init];
    
    if (self != nil) {
        _megaChatListItemList = megaChatListItemList;
        _cMemoryOwn = cMemoryOwn;
    }
    
    return self;
}

- (void)dealloc {
    if (self.cMemoryOwn){
        delete _megaChatListItemList;
    }
}

- (instancetype)clone {
    return self.megaChatListItemList ? [[MEGAChatListItemList alloc] initWithMegaChatListItemList:self.megaChatListItemList cMemoryOwn:YES] : nil;
}

- (MegaChatListItemList *)getCPtr {
    return self.megaChatListItemList;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: size=%ld>",
            [self class], (long)self.size];
}

- (NSUInteger)size {
    return self.megaChatListItemList->size();
}

- (MEGAChatListItem *)chatListItemAtIndex:(NSUInteger)index {
    return self.megaChatListItemList->get((unsigned int)index) ? [[MEGAChatListItem alloc] initWithMegaChatListItem:self.megaChatListItemList->get((unsigned int)index)->copy() cMemoryOwn:YES] : nil;
}

@end
