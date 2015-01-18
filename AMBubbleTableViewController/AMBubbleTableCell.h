//
//  AMBubbleTableCell.h
//  AMBubbleTableViewController
//
//  Created by Andrea Mazzini on 30/06/13.
//  Copyright (c) 2013 Andrea Mazzini. All rights reserved.
//

#import "AMBubbleGlobals.h"
#import "AMBubbleFlatAccessoryView.h"

@interface AMBubbleTableCell : UITableViewCell

@property (nonatomic, strong) UIImageView* msgImageView;
@property (nonatomic, strong) UITextView*	textView;
@property (nonatomic, strong) UIImageView*	imageBackground;
@property (nonatomic, strong) UILabel*		labelUsername;
@property (nonatomic, strong) AMBubbleFlatAccessoryView*		bubbleAccessory;
@property (nonatomic, strong) UIButton*     errorIcon;
@property (nonatomic, strong) UIButton*     voiceButton;
@property (nonatomic, readonly) AMBubbleCellType cellType;

- (id)initWithOptions:(NSDictionary*)options reuseIdentifier:(NSString *)reuseIdentifier;
- (void)setupCellWithType:(AMBubbleCellType)type withWidth:(float)width andParams:(NSDictionary*)params;
- (void)setMessageImageGesture:(UIGestureRecognizer *)gesture;

- (UIImageView *)avatarImageView;
@end
