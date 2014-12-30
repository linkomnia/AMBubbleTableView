//
//  AnyRecorder.m
//  Pods
//
//  Created by Cat Jia on 30/12/14.
//
//

#import "AnyRecorder.h"

@implementation AnyRecorder

-(float)recordedTime
{
    return 0;
}
-(void)startRecording
{
    if (self.delegate) {
        [self.delegate didStartRecording];
    }
}
-(void)finishRecording
{
    if (self.delegate) {
        [self.delegate didFinishRecording];
    }
}
-(void)cancelRecording
{
    if (self.delegate) {
        [self.delegate didCancelRecording];
    }
}

@end
