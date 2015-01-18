//
//  AMBubbleTableViewController.h
//  AMBubbleTableViewController
//
//  Created by Andrea Mazzini on 30/06/13.
//  Copyright (c) 2013 Andrea Mazzini. All rights reserved.
//

#import "AMBubbleGlobals.h"
#import "AMBubbleTableCell.h"

@interface AMBubbleTableViewController : UIViewController

@property (nonatomic, strong) UITableView*	tableView;
@property (nonatomic, strong) UITextView*	textView;
@property (nonatomic, assign) id<AMBubbleTableDataSource> dataSource;
@property (nonatomic, assign) id<AMBubbleTableDelegate> delegate;


- (void)reloadTableScrollingToBottom:(BOOL)scroll;
- (void)setTableStyle:(AMBubbleTableStyle)style withCustomStyles:(NSDictionary *)customStyles;
- (void)setBubbleTableOptions:(NSDictionary *)options;
- (void)setTableStyle:(AMBubbleTableStyle)style;
- (void)scrollToBottomAnimated:(BOOL)animated;
- (void)setupChatTextFieldBar:(UIView *)containerView textView:(UITextView *)textView sendButton:(UIButton *)sendButton selectImageButton:(UIButton *)selectImageButton voiceButton:(UIButton *)voiceButton;
- (void)setupVoiceBar:(UIView *)containerView closeButton:(UIButton *)closeButton recordButton:(UIButton *)recordButton backgroundView:(UIView *)backgroundView voiceLength:(CGFloat *)voiceLengthInSecond;
- (void)customizeAMBubbleTableCell:(AMBubbleTableCell *)cell forCellType:(AMBubbleCellType)cellType atIndexPath:(NSIndexPath *) indexPath;

- (void)didStartRecording;
- (void)didFinishRecording:(NSString *)filePath duration:(NSTimeInterval)duration;
- (void)didCancelRecording;

@end
