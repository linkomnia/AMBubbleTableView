//
//  AnyRecorder.h
//  Pods
//
//  Created by Cat Jia on 30/12/14.
//
//

#import <Foundation/Foundation.h>
#import "AnyRecorderDelegate.h"

@interface AnyRecorder : NSObject

@property (nonatomic, strong) id<AnyRecorderDelegate> delegate;

-(float)recordedTime;
-(void)startRecording;
-(void)finishRecording;
-(void)cancelRecording;

@end
