//
//  AnyRecorder.h
//  Pods
//
//  Created by Cat Jia on 30/12/14.
//
//

#import <Foundation/Foundation.h>
#import "AnyRecorderDelegate.h"
#import "AnyRecorderControl.h"

@interface AnyRecorder : NSObject <AnyRecorderControl>

@property (nonatomic, strong) id<AnyRecorderDelegate> delegate;

@end
