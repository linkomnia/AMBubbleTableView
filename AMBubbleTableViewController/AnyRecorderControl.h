//
//  AnyRecorderControl.h
//  Pods
//
//  Created by Cat Jia on 30/12/14.
//
//

#import <Foundation/Foundation.h>

@protocol AnyRecorderControl <NSObject>

-(float)recordedTime;
-(void)startRecording;
-(void)finishRecording;
-(void)cancelRecording;

@end
