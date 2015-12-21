//
//  ObjCUtils.m
//  Kyooz
//
//  Created by FAHAD RIAZ on 12/5/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

#import "ObjCUtils.h"

@implementation ObjCUtils {
    NSString *_selectorString;
}

- (id)init {
    self = [super init];
    NSArray *sel1 = @[@"nowPlayingItem", @""];
    NSArray *sel2 = @[@"at", @""];
    NSArray *sel3 = @[@"index:", @""];
    
    NSString *ab = [[NSString alloc] initWithFormat:@"%@%@%@", sel1[0], [sel2[0] capitalizedString], [sel3[0] capitalizedString]];
    
    
    if (self) {
        _selectorString = ab;
    }
    return self;
}



- (MPMediaItem *)getItemForPlayer:(MPMusicPlayerController *)musicPlayer forIndex:(NSInteger)index {
    SEL selector = NSSelectorFromString(_selectorString);
    if (![musicPlayer respondsToSelector:selector]) {
        return nil;
    }
    
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[MPMusicPlayerController instanceMethodSignatureForSelector:selector]];
    [invocation setSelector:selector];
    [invocation setTarget:musicPlayer];
    [invocation setArgument:&index atIndex:2];
    
    [invocation invoke];
    
    //getReturnValue does not copy a safe/retained object into the pointer passed in, but ARC is not aware of this and assumes that it is retained
    //need to explicityly declare this pointer as unsafe unretained so that ARC doesnt deallocate the object once its out of scope
    MPMediaItem * __unsafe_unretained returnValue;
    [invocation getReturnValue:&returnValue];
    
    //in addition to declaring the above value as unsafe unretained, we must assign the unsafe pointer to a strong reference before returning the value
    //in order for it not to be deallocated before it is used
    MPMediaItem *mediaItem = returnValue;
    return mediaItem;
}

@end