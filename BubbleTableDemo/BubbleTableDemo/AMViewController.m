//
//  AMViewController.m
//  BubbleTableDemo
//
//  Created by Andrea on 21/01/14.
//  Copyright (c) 2014 Fancy Pixel. All rights reserved.
//

#import "AMViewController.h"

@interface AMViewController () <AMBubbleTableDataSource, AMBubbleTableDelegate>

@property (nonatomic, strong) NSMutableArray* data;

@end

@implementation AMViewController

- (void)viewDidLoad
{
	// Bubble Table setup
	
	[self setDataSource:self]; // Weird, uh?
	[self setDelegate:self];
	
	[self setTitle:@"Chat"];
	
	// Dummy data
	self.data = [[NSMutableArray alloc] initWithArray:@[
														@{
															@"text": @"He felt that his whole life was some kind of dream and he sometimes wondered whose it was and whether they were enjoying it.",
															@"date": [NSDate date],
															@"type": @(AMBubbleCellReceived),
															@"username": @"Stevie",
															@"color": [UIColor redColor]
															},
														@{
															@"text": @"My dad isn’t famous. My dad plays jazz. You can’t get famous playing jazz",
															@"date": [NSDate date],
															@"type": @(AMBubbleCellSent)
															},
														@{
															@"date": [NSDate date],
															@"type": @(AMBubbleCellTimestamp)
															},
														@{
															@"text": @"I'd far rather be happy than right any day.",
															@"date": [NSDate date],
															@"type": @(AMBubbleCellReceived),
															@"username": @"John",
															@"color": [UIColor orangeColor]
															},
														@{
															@"text": @"The only reason for walking into the jaws of Death is so's you can steal His gold teeth.",
															@"date": [NSDate date],
															@"type": @(AMBubbleCellSent)
															},
														@{
															@"text": @"The gods had a habit of going round to atheists' houses and smashing their windows.",
															@"date": [NSDate date],
															@"type": @(AMBubbleCellReceived),
															@"username": @"Jimi",
															@"color": [UIColor blueColor]
															},
														@{
															@"text": @"you are lucky. Your friend is going to meet Bel-Shamharoth. You will only die.",
															@"date": [NSDate date],
															@"type": @(AMBubbleCellSent)
															},
														@{
															@"text": @"Guess the quotes!",
															@"date": [NSDate date],
															@"type": @(AMBubbleCellSent)
															},
														]
				 ];
	
	// Set a style
	[self setTableStyle:AMBubbleTableStyleFlat];
	
	[self setBubbleTableOptions:@{AMOptionsBubbleDetectionType: @(UIDataDetectorTypeAll),
								  AMOptionsBubblePressEnabled: @NO,
								  AMOptionsBubbleSwipeEnabled: @NO}];
	
	// Call super after setting up the options
	[super viewDidLoad];
    
    [self.tableView setContentInset:UIEdgeInsetsMake(64, 0, 0, 0)];
    
//    [self fakeMessages];
}

- (void)fakeMessages
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self didSendText:@"Fake message here!"];
        [self fakeMessages];
    });
}

- (void)swipedCellAtIndexPath:(NSIndexPath *)indexPath withFrame:(CGRect)frame andDirection:(UISwipeGestureRecognizerDirection)direction
{
	NSLog(@"swiped");
}

#pragma mark - AMBubbleTableDataSource

- (NSInteger)numberOfRows
{
	return self.data.count;
}

- (AMBubbleCellType)cellTypeForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return [self.data[indexPath.row][@"type"] intValue];
}

- (NSString *)textForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return self.data[indexPath.row][@"text"];
}

- (UIImage*)msgImageForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [UIImage imageNamed:@"demo"];
}


- (NSDate *)timestampForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return [NSDate date];
}

- (UIImage*)avatarForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return [UIImage imageNamed:@"avatar"];
}

#pragma mark - AMBubbleTableDelegate

- (void)didSendText:(NSString*)text
{
	NSLog(@"User wrote: %@", text);
	
	[self.data addObject:@{ @"text": text,
							@"date": [NSDate date],
							@"type": @(AMBubbleCellSent)
							}];
	
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(self.data.count - 1) inSection:0];
	[self.tableView beginUpdates];
	[self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
	[self.tableView endUpdates];
    // Either do this:
    [self scrollToBottomAnimated:YES];
    // or this:
	// [super reloadTableScrollingToBottom:YES];
}

- (NSString*)usernameForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return self.data[indexPath.row][@"username"];
}

- (UIColor*)usernameColorForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return self.data[indexPath.row][@"color"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
