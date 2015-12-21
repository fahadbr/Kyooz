//
//  ObjCUtils.h
//  Kyooz
//
//  Created by FAHAD RIAZ on 12/5/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

#ifndef ObjCUtils_h
#define ObjCUtils_h

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface ObjCUtils : NSObject
    
- (MPMediaItem *) getItemForPlayer:(MPMusicPlayerController *)musicPlayer forIndex:(NSInteger)index;
    
@end


#endif /* ObjCUtils_h */
