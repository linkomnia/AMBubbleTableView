//
//  AnyRecorderDelegate.h
//  Pods
//
//  Created by Cat Jia on 30/12/14.
//
//

#import <Foundation/Foundation.h>

@protocol AnyRecorderDelegate <NSObject>

-(void)didFinishRecording;
-(void)didStartRecording;
-(void)didCancelRecording;

@end
