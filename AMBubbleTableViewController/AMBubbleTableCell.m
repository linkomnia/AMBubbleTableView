//
//  AMBubbleTableCell.m
//  AMBubbleTableViewController
//
//  Created by Andrea Mazzini on 30/06/13.
//  Copyright (c) 2013 Andrea Mazzini. All rights reserved.
//

#import "AMBubbleTableCell.h"
#import "AMBubbleAccessoryView.h"
#import <QuartzCore/QuartzCore.h>

@interface AMBubbleTableCell ()

@property (nonatomic, weak)   NSDictionary* options;


@end

@implementation AMBubbleTableCell

- (id)initWithOptions:(NSDictionary*)options reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
		self.options = options;
		self.backgroundColor = [UIColor clearColor];
		self.selectionStyle = UITableViewCellSelectionStyleNone;
		self.accessoryType = UITableViewCellAccessoryNone;
		self.textView = [[UITextView alloc] init];
		self.imageBackground = [[UIImageView alloc] init];
		self.labelUsername = [[UILabel alloc] init];
		self.bubbleAccessory = [[NSClassFromString(options[AMOptionsAccessoryClass]) alloc] init];
        self.msgImageView = [[UIImageView alloc] init];
		[self.bubbleAccessory setOptions:options];
		[self.contentView addSubview:self.imageBackground];
		[self.imageBackground addSubview:self.textView];
        [self.imageBackground addSubview:self.msgImageView];
		[self.imageBackground addSubview:self.labelUsername];
		[self.contentView addSubview:self.bubbleAccessory];
		[self.textView setUserInteractionEnabled:YES];
		[self.imageBackground setUserInteractionEnabled:YES];
        self.errorIcon = [[UIButton alloc]init];
        [self.errorIcon setImage:[UIImage imageNamed:@"res/images/icon_error"] forState:UIControlStateNormal];
        self.errorIcon.hidden = YES;
        self.voiceButton = [[UIButton alloc]init];
        [self.imageBackground addSubview:self.voiceButton];
    }
    return self;
}

- (void)setupCellWithType:(AMBubbleCellType)type withWidth:(float)width andParams:(NSDictionary*)params
{
	UIFont* textFont = self.options[AMOptionsBubbleTextFont];
	
	CGRect content = self.contentView.frame;
	content.size.width = width;
	self.contentView.frame = content;
	self.frame = content;
	// Configure the cell to show the message in a bubble. Layout message cell & its subviews.
	CGSize sizeText = [params[@"text"] sizeWithFont:textFont
								  constrainedToSize:CGSizeMake(kMessageTextWidth, CGFLOAT_MAX)
									  lineBreakMode:NSLineBreakByWordWrapping];

    CGRect voiceFrame = CGRectMake(0, 0, 0, 0);
    if (params[@"msgVoiceURL"]) {
        NSString * fakeText = @"0.00s";
        sizeText = [fakeText sizeWithFont:textFont
                        constrainedToSize:CGSizeMake(kMessageTextWidth, CGFLOAT_MAX)
                            lineBreakMode:NSLineBreakByWordWrapping];
        if (params[@"voiceLength"]) {
            float voiceLength = [params[@"voiceLength"] floatValue];
            sizeText = CGSizeMake(sizeText.width + voiceLength * 10, sizeText.height);
        }
    }

    CGSize sizeImage;
    if (params[@"msgImage"]) {
        UIImage *img = params[@"msgImage"];
        CGFloat width = 0, height = 0;
        if (img.size.width > img.size.height) {
            width = kMessageImageWidth;
            height = img.size.height / img.size.width * width;
        } else {
            height = kMessageImageHeight;
            width = img.size.width / img.size.height * height;
        }
        sizeImage = CGSizeMake(width, height);
    } else {
        sizeImage = CGSizeMake(0, 0);
    }
    //NSLog(@"%f, %f", sizeImage.width, sizeImage.height);
    
    
	
	
	[self.textView setBackgroundColor:[UIColor clearColor]];
	[self.textView setFont:textFont];
	[self.textView setEditable:NO];
	[self.textView setScrollEnabled:NO];
	[self.textView setDataDetectorTypes:[self.options[AMOptionsBubbleDetectionType] intValue]];
	if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
#ifdef __IPHONE_7_0
		[self.textView setSelectable:YES];
		[self.textView.textContainer setLineFragmentPadding:0];
		[self.textView setTextContainerInset:UIEdgeInsetsZero];
#endif
	} else {
		[self.textView setContentInset:UIEdgeInsetsMake(-8,-8,-8,-8)];
	}
	[self.textView setTextColor:self.options[AMOptionsTextFieldFontColor]];
	
	[self.bubbleAccessory setupView:params];
	
    _cellType = type;
    
	// Right Bubble
	if (type == AMBubbleCellSent) {
		
		[self.bubbleAccessory setFrame:CGRectMake(width - self.bubbleAccessory.frame.size.width - 2,
												  2,
												  self.bubbleAccessory.frame.size.width,
												  self.bubbleAccessory.frame.size.height)];
		
		
		CGRect rect = CGRectMake(width - MAX(sizeText.width, sizeImage.width) - 34.0f - self.bubbleAccessory.frame.size.width,
								 textFont.lineHeight - 13.0f,
								 MAX(sizeText.width, sizeImage.width) + 34.0f,
								 sizeText.height + sizeImage.height + 12.0f);
		
		if (rect.size.height > self.bubbleAccessory.frame.size.height) {
			if ([self.options[AMOptionsAccessoryPosition] intValue] == AMBubbleAccessoryDown) {
				CGRect frame = self.bubbleAccessory.frame;
				frame.origin.y += rect.size.height - self.bubbleAccessory.frame.size.height;
				self.bubbleAccessory.frame = frame;
			}
		} else {
			if ([self.options[AMOptionsAccessoryPosition] intValue] == AMBubbleAccessoryDown) {
				rect.origin.y += self.bubbleAccessory.frame.size.height - rect.size.height;
			} else {
				rect.origin.y = 0;
			}
		}
        
        CGRect textFrame = CGRectMake(12.0f,
                                      4.0f,
                                      sizeText.width + 5.0f,
                                      sizeText.height);
        if (params[@"msgVoiceURL"]) {
            voiceFrame = textFrame;
        }
		
		[self setupBubbleWithType:type
					   background:rect
						textFrame:textFrame
                    msgImageFrame:CGRectMake(12.0f, 4.0f + sizeText.height, sizeImage.width + 5.0f, sizeImage.height)
                       voiceFrame:voiceFrame
						  andTextParams:params];
	}
	
	if (type == AMBubbleCellReceived) {
		
		[self.bubbleAccessory setFrame:CGRectMake(2,
												  2,
												  self.bubbleAccessory.frame.size.width,
												  self.bubbleAccessory.frame.size.height)];
		CGSize usernameSize = CGSizeZero;
		
		if (![params[@"username"] isEqualToString:@""]) {
			UIFont* fontUsername = self.options[AMOptionsUsernameFont];
			[self.labelUsername setFont:fontUsername];
			usernameSize = [params[@"username"] sizeWithFont:fontUsername
										   constrainedToSize:CGSizeMake(kMessageTextWidth, self.labelUsername.font.lineHeight)
											   lineBreakMode:NSLineBreakByWordWrapping];
			[self.labelUsername setNumberOfLines:1];
			[self.labelUsername setFrame:CGRectMake(22.0f, fontUsername.lineHeight - 9.0f, usernameSize.width+5.0f, usernameSize.height)];
			[self.labelUsername setBackgroundColor:[UIColor clearColor]];
			if ([params[@"color"] isKindOfClass:[UIColor class]]) {
				[self.labelUsername setTextColor:params[@"color"]];
			}
			[self.labelUsername setText:params[@"username"]];
		}
		
		CGRect rect = CGRectMake(0.0f + self.bubbleAccessory.frame.size.width,
								 textFont.lineHeight - 13.0f,
								 MAX(MAX(sizeText.width, sizeImage.width), usernameSize.width) + 34.0f, // Accounts for usernames longer than text
								 sizeText.height + sizeImage.height + 12.0f + usernameSize.height);
		
		if (rect.size.height > self.bubbleAccessory.frame.size.height) {
			if ([self.options[AMOptionsAccessoryPosition] intValue] == AMBubbleAccessoryDown) {
				CGRect frame = self.bubbleAccessory.frame;
				frame.origin.y += rect.size.height - self.bubbleAccessory.frame.size.height;
				self.bubbleAccessory.frame = frame;
			}
		} else {
			if ([self.options[AMOptionsAccessoryPosition] intValue] == AMBubbleAccessoryDown) {
				rect.origin.y += self.bubbleAccessory.frame.size.height - rect.size.height;
			} else {
				rect.origin.y = 0;
			}
		}
		
        CGRect textFrame = CGRectMake(22.0f, 4.0 + usernameSize.height, sizeText.width + 5.0f, sizeText.height);
        if (params[@"msgVoiceURL"]) {
            voiceFrame = textFrame;
        }

		[self setupBubbleWithType:type
					   background:rect
						textFrame:textFrame
                    msgImageFrame:CGRectMake(22.0f, 4.0 + usernameSize.height + sizeText.height, sizeImage.width + 5.0, sizeImage.height)
                       voiceFrame:voiceFrame
						  andTextParams:params];
	}
	
	if (type == AMBubbleCellTimestamp) {
		[self.textView setDataDetectorTypes:UIDataDetectorTypeNone];
		[self.bubbleAccessory setFrame:CGRectZero];
		
		self.textView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
		[self.textView setTextAlignment:NSTextAlignmentCenter];
        [self.textView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
		[self.textView setFont:self.options[AMOptionsTimestampFont]];
		[self.textView setTextColor:[UIColor colorWithRed:100.0f/255.0f green:120.0f/255.0f blue:150.0f/255.0f alpha:1]];
		[self.textView setText:params[@"text"]];
		[self.imageBackground setFrame:CGRectZero];
		self.textView.text = params[@"date"];
	}
    	
	[self setNeedsLayout];
	
}

- (void)setupBubbleWithType:(AMBubbleCellType)type background:(CGRect)frame textFrame:(CGRect)textFrame msgImageFrame:(CGRect)msgImageFrame voiceFrame:(CGRect) voiceFrame andTextParams:(NSDictionary*)textParams
{
	[self.imageBackground setFrame:frame];
    
    _cellType = type;

	if (type == AMBubbleCellReceived) {
		[self.imageBackground setImage:self.options[AMOptionsImageIncoming]];
	} else {
		[self.imageBackground setImage:self.options[AMOptionsImageOutgoing]];
	}
	
	[self.imageBackground setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
	
	// Dirty fix for ios previous than 7.0
	if (!SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
		textFrame.size.width += 12;
        msgImageFrame.size.width += 12;
	}
	[self.textView setFrame:textFrame];
	[self.textView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
	[self.textView setText:nil];
	[self.textView setText:textParams[@"text"]];
    [self.msgImageView setFrame:msgImageFrame];
    if (textParams[@"msgImage"]) {
        self.msgImageView.image = textParams[@"msgImage"];
    } else {
        self.msgImageView.image = nil;
    }
    
    [self.voiceButton setFrame:voiceFrame];
    [self.voiceButton setTitle:@"[VOICE]" forState:UIControlStateNormal];
    [self.voiceButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    [self.errorIcon sizeToFit];
    [self addSubview:self.errorIcon];
    self.errorIcon.frame = CGRectMake(self.imageBackground.frame.origin.x - self.errorIcon.frame.size.width - 15, self.bubbleAccessory.frame.origin.y + (self.bubbleAccessory.imageAvatar.frame.size.height - self.errorIcon.frame.size.height) / 2, self.errorIcon.frame.size.width, self.errorIcon.frame.size.height);
    
    //[self.imageView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
    
    NSLog(@"%f, %f, %f, %f", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
    NSLog(@"%f, %f, %f, %f", textFrame.origin.x, textFrame.origin.y, textFrame.size.width, textFrame.size.height);
    NSLog(@"%f, %f, %f, %f", msgImageFrame.origin.x, msgImageFrame.origin.y, msgImageFrame.size.width, msgImageFrame.size.height);
    
}

-(void)setMessageImageGesture:(UIGestureRecognizer *)gesture
{
    if (!self.msgImageView) {
        return;
    }
    for (UIGestureRecognizer * exsiting in self.msgImageView.gestureRecognizers) {
        [self.msgImageView removeGestureRecognizer:exsiting];
    }
    [self.msgImageView addGestureRecognizer:gesture];
    self.msgImageView.userInteractionEnabled = YES;
}

-(UIImageView *)avatarImageView
{
    return self.bubbleAccessory.imageAvatar;
}


@end
