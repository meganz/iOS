
#import "SearchOperation.h"
#import "MEGASdkManager.h"

@interface SearchOperation ()

@property (strong, nonatomic) MEGANode *parentNode;
@property (strong, nonatomic) NSString *text;
@property (copy, nonatomic) void (^completion)(NSArray *searchNodes);

@end

@implementation SearchOperation

- (instancetype)initWithParentNode:(MEGANode *)parentNode text:(NSString *)text completion:(void (^)(NSArray * _Nullable))completion {
    self = super.init;
    if (self) {
        _parentNode = parentNode;
        _text = text;
        _completion = completion;
    }
    return self;
}

- (void)start {
    if (self.isCancelled) {
        [self finishOperation];
        if (self.completion) {
            self.completion(nil);
        }
        return;
    }
    
    [self startExecuting];
    
    MEGALogInfo(@"[Search] \"%@\" starts", self.text);
    
    MEGANodeList *allNodeList = [MEGASdkManager.sharedMEGASdk nodeListSearchForNode:self.parentNode searchString:self.text recursive:YES];
    
    MEGALogInfo(@"[Search] \"%@\" finishes", self.text);
    
    [self finishOperation];
    
    if (self.completion) {
        if (self.isCancelled) {
            MEGALogInfo(@"[Search] \"%@\" canceled", self.text);
            self.completion(nil);
        } else {
            NSMutableArray *searchNodes = NSMutableArray.new;
            for (NSInteger i = 0; i < allNodeList.size.integerValue; i++) {
                MEGANode *n = [allNodeList nodeAtIndex:i];
                [searchNodes addObject:n];
            }            
            MEGALogInfo(@"[Search] %ld nodes found and added to the array", (long) searchNodes.count);
            self.completion(searchNodes.copy);
        }
    }
}

@end
