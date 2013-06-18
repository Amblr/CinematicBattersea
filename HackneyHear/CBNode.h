//
//  ATNode.h
//  AmblrTravel
//
//  Created by Joe Zuntz on 17/01/2013.
//  Copyright (c) 2013 Imperial College London. All rights reserved.
//

#import "L1Node.h"

typedef enum CBSoundType {
    CBSoundTypeSpeech,
    CBSoundTypeBed,
    CBSoundTypeMusic,
    CBSoundTypeAtmos,
    CBSoundTypeIntro,
} CBSoundType ;

@interface CBNode : L1Node
{
    CBSoundType soundType;
}
@property (assign) CBSoundType soundType;
-(void) determineType;
@end
