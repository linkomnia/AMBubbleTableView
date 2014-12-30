//
//  AMBubbleTableViewController.m
//  AMBubbleTableViewController
//
//  Created by Andrea Mazzini on 30/06/13.
//  Copyright (c) 2013 Andrea Mazzini. All rights reserved.
//

#import "AMBubbleTableViewController.h"
#import "AnyRecorder.h"

#define kInputHeight 40.0f
#define kLineHeight 30.0f
#define kButtonWidth 78.0f


@interface AMBubbleTableViewController () <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate>

@property (strong, nonatomic) NSMutableDictionary*	options;
@property (nonatomic, strong) UIView*               imageInput;
@property (nonatomic, strong) UIButton*             buttonSend;
@property (nonatomic, strong) NSDateFormatter*      dateFormatter;
@property (nonatomic, strong) UITextView*           tempTextView;
@property (nonatomic, assign) float                 previousTextFieldHeight;
@property (nonatomic, strong) UIButton*             buttonImageChooser;
@property (nonatomic, strong) UIButton*             buttonVoice;
@property (nonatomic, strong) UIView*               voiceBar;
@property (nonatomic, strong) UIButton*             voiceRecordButton;
@property (nonatomic, strong) UIProgressView*       voiceProgressView;
@property (nonatomic) NSTimer*                      recordTimer;

@end

@implementation AMBubbleTableViewController

{
    CGFloat voiceLengthInSecond;
    BOOL isRecording;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	[self setupView];
}

- (void)setBubbleTableOptions:(NSDictionary *)options
{
	[self.options addEntriesFromDictionary:options];
}

- (NSMutableDictionary*)options
{
	if (_options == nil) {
		_options = [[AMBubbleGlobals defaultOptions] mutableCopy];
	}
	return _options;
}

- (void)setTableStyle:(AMBubbleTableStyle)style
{
    switch (style) {
        case AMBubbleTableStyleDefault:
            [self.options addEntriesFromDictionary:[AMBubbleGlobals defaultStyleDefault]];
            break;
        case AMBubbleTableStyleSquare:
            [self.options addEntriesFromDictionary:[AMBubbleGlobals defaultStyleSquare]];
            break;
        case AMBubbleTableStyleFlat:
            [self.options addEntriesFromDictionary:[AMBubbleGlobals defaultStyleFlat]];
            break;
        default:
            break;
    }
}

- (void)setTableStyle:(AMBubbleTableStyle)style withCustomStyles:(NSDictionary *)customStyles
{
    [self setTableStyle:style];
    [self.options addEntriesFromDictionary:customStyles];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleKeyboardWillShow:)
												 name:UIKeyboardWillShowNotification
                                               object:nil];
    
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleKeyboardWillHide:)
												 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)setupView
{
	UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
																						action:@selector(handleTapGesture:)];
	// Table View
    CGRect tableFrame = CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height - kInputHeight);
	self.tableView = [[UITableView alloc] initWithFrame:tableFrame style:UITableViewStylePlain];
	[self.tableView addGestureRecognizer:gestureRecognizer];
	[self.tableView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
	[self.tableView setDataSource:self];
	[self.tableView setDelegate:self];
	[self.tableView setBackgroundColor:self.options[AMOptionsBubbleTableBackground]];
	[self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
	[self.view addSubview:self.tableView];
	
    // Input background
    CGRect inputFrame = CGRectMake(0.0f, self.view.frame.size.height - kInputHeight, self.view.frame.size.width, kInputHeight);
    if (self.options[AMOptionsImageBar] != [NSNull null]) {
        self.imageInput = [[UIImageView alloc] init];
        ((UIImageView *)self.imageInput).image = self.options[AMOptionsImageBar];
    } else {
        self.imageInput = [[UIView alloc]init];
        self.imageInput.backgroundColor = [UIColor whiteColor];
    }
	[self.imageInput setFrame:inputFrame];
	[self.imageInput setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin)];
	[self.imageInput setUserInteractionEnabled:YES];
	
	[self.view addSubview:self.imageInput];
    
    
    ///// alloc init views
    // text field
    CGFloat width = self.imageInput.frame.size.width - kButtonWidth - 60.0f - 3;
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(6.0f + 60.0f + 3, 3.0f, width, kLineHeight)];
    [self.textView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [self.textView setScrollsToTop:NO];
    [self.textView setUserInteractionEnabled:YES];
    [self.textView setFont:self.options[AMOptionsTextFieldFont]];
    [self.textView setTextColor:self.options[AMOptionsTextFieldFontColor]];
    [self.textView setBackgroundColor:self.options[AMOptionsTextFieldBackground]];
    [self.textView setKeyboardAppearance:UIKeyboardAppearanceDefault];
    [self.textView setKeyboardType:UIKeyboardTypeDefault];
    [self.textView setReturnKeyType:UIReturnKeyDefault];
    [self.textView setDelegate:self];
    [self.imageInput addSubview:self.textView];
    
		
	// This text view is used to get the content size
	self.tempTextView = [[UITextView alloc] init];
    self.tempTextView.font = self.textView.font;
    self.tempTextView.text = @"";
    CGSize size = [self.tempTextView sizeThatFits:CGSizeMake(self.textView.frame.size.width, FLT_MAX)];
    self.previousTextFieldHeight = size.height;
    
	// Send button
    self.buttonSend = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.buttonSend setAutoresizingMask:(UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin)];
    
    if (self.options[AMOptionsImageButton] != [NSNull null]) {
        UIImage *sendBack = self.options[AMOptionsImageButton];
        [self.buttonSend setBackgroundImage:sendBack forState:UIControlStateNormal];
        [self.buttonSend setBackgroundImage:sendBack forState:UIControlStateDisabled];
    }
    if (self.options[AMOptionsImageButtonHighlight] != [NSNull null]) {
        UIImage *sendBackHighLighted = self.options[AMOptionsImageButtonHighlight];
        [self.buttonSend setBackgroundImage:sendBackHighLighted forState:UIControlStateHighlighted];
    }
	[self.buttonSend.titleLabel setFont:self.options[AMOptionsButtonFont]];

    NSString *title = NSLocalizedString(@"Send",);
    [self.buttonSend setTitle:title forState:UIControlStateNormal];
    [self.buttonSend setTitle:title forState:UIControlStateHighlighted];
    [self.buttonSend setTitle:title forState:UIControlStateDisabled];
    self.buttonSend.titleLabel.font = [UIFont boldSystemFontOfSize:16.0f];
    
    [self.buttonSend setEnabled:NO];
    [self.buttonSend setFrame:CGRectMake(self.imageInput.frame.size.width - 65.0f, [self.options[AMOptionsButtonOffset] floatValue], 59.0f, 26.0f)];
    [self.buttonSend addTarget:self	action:@selector(sendPressed:) forControlEvents:UIControlEventTouchUpInside];
	
    [self.imageInput addSubview:self.buttonSend];
    
    self.buttonImageChooser = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.buttonImageChooser setImage:[UIImage imageNamed:@"photoIcon"] forState:UIControlStateNormal];
    self.buttonImageChooser.frame = CGRectMake(6.0f, [self.options[AMOptionsButtonOffset] floatValue], 26.0f, 26.0f);
    [self.buttonImageChooser addTarget:self action:@selector(clickChooseImage:) forControlEvents:UIControlEventTouchUpInside];
    [self.imageInput addSubview:self.buttonImageChooser];

    self.buttonVoice = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.buttonVoice setImage:[UIImage imageNamed:@"voiceIcon"] forState:UIControlStateNormal];
    self.buttonVoice.frame = CGRectMake(self.buttonImageChooser.frame.origin.x + self.buttonImageChooser.frame.size.width + 3.0f, [self.options[AMOptionsButtonOffset] floatValue], 26.0f, 26.0f);
    [self.buttonVoice addTarget:self action:@selector(clickVoiceButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.imageInput addSubview:self.buttonVoice];
    
    
    
    // styles which can be customized
    [self setupChatTextFieldBar:self.imageInput textView:self.textView sendButton:self.buttonSend selectImageButton:self.buttonImageChooser voiceButton:self.buttonVoice];
    
    // Voice Bar (shown when tap Voice Icon)
    self.voiceBar = [[UIView alloc]initWithFrame:self.imageInput.bounds];
    self.voiceBar.backgroundColor = [UIColor colorWithRed:0.24 green:0.59 blue:1 alpha:1];
    self.voiceBar.hidden = YES;
    [self.imageInput addSubview:self.voiceBar];
    
    UIView * voiceBarBackgroundView = [[UIView alloc]initWithFrame:self.voiceBar.bounds];
    voiceBarBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.voiceBar addSubview:voiceBarBackgroundView];
    
    UIButton * voiceCloseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [voiceCloseButton setImage:[UIImage imageNamed:@"closeIcon"] forState:UIControlStateNormal];
    voiceCloseButton.frame = self.buttonImageChooser.frame;
    [voiceCloseButton addTarget:self action:@selector(clickVoiceCloseButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.voiceBar addSubview:voiceCloseButton];
    
    self.voiceRecordButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.voiceRecordButton.frame = CGRectMake(voiceCloseButton.frame.origin.x + voiceCloseButton.frame.size.width, 0, self.voiceBar.frame.size.width - voiceCloseButton.frame.origin.x - voiceCloseButton.frame.size.width, self.voiceBar.frame.size.height);
    [self.voiceRecordButton setTitle:@"Hold to Speak" forState:UIControlStateNormal];
    [self.voiceRecordButton setTitle:@"Release to Send" forState:UIControlStateHighlighted];
    [self.voiceRecordButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.voiceBar addSubview:self.voiceRecordButton];

    isRecording = NO;
    [self.voiceRecordButton addTarget:self action:@selector(voiceRecordButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [self.voiceRecordButton addTarget:self action:@selector(voiceRecordButtonTouchUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
    
    [self.voiceRecordButton addTarget:self action:@selector(touchDownRecordButton:) forControlEvents:UIControlEventTouchDown];
    
    self.voiceProgressView = [[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleBar];
    [self.voiceProgressView sizeToFit];
    self.voiceProgressView.frame = CGRectMake(0, 0, self.voiceBar.frame.size.width, self.voiceProgressView.frame.size.height);
    self.voiceProgressView.progressTintColor = [UIColor whiteColor];
    self.voiceProgressView.trackTintColor = [UIColor clearColor];
    [self.voiceBar addSubview:self.voiceProgressView];

    voiceLengthInSecond = 10.0;
    self.voiceRecorder = [[AnyRecorder alloc]init];
    ((AnyRecorder *)self.voiceRecorder).delegate = self;
    self.recordTimer = [[NSTimer alloc]init];
    
    // styles which can be customized
    [self setupVoiceBar:self.voiceBar closeButton:voiceCloseButton recordButton:self.voiceRecordButton backgroundView:voiceBarBackgroundView voiceLength:&(voiceLengthInSecond)];
    
    
}

-(void)setupChatTextFieldBar:(UIView *)containerView textView:(UITextView *)textView sendButton:(UIButton *)sendButton selectImageButton:(UIButton *)selectImageButton voiceButton:(UIButton *)voiceButton
{
    // Input field
    [self.textView setScrollIndicatorInsets:UIEdgeInsetsMake(10.0f, 0.0f, 10.0f, 8.0f)];
    [self.textView setContentInset:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
    
    // Input field's background
    UIImageView * imageInputBack = [[UIImageView alloc] initWithFrame:CGRectMake(self.textView.frame.origin.x - 1.0f,
                                                                                 0.0f,
                                                                                 self.textView.frame.size.width + 2.0f,
                                                                                 self.imageInput.frame.size.height)];
    [imageInputBack setImage:self.options[AMOptionsImageInput]];
    [imageInputBack setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
    [imageInputBack setBackgroundColor:[UIColor clearColor]];
    [imageInputBack setUserInteractionEnabled:NO];
    [self.imageInput addSubview:imageInputBack];
    
    // button title shadow
    UIColor *titleShadow = [UIColor colorWithRed:0.325f green:0.463f blue:0.675f alpha:1.0f];
    [self.buttonSend setTitleShadowColor:titleShadow forState:UIControlStateNormal];
    [self.buttonSend setTitleShadowColor:titleShadow forState:UIControlStateHighlighted];
    self.buttonSend.titleLabel.shadowOffset = CGSizeMake(0.0f, -1.0f);
    
    [self.buttonSend setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.buttonSend setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [self.buttonSend setTitleColor:[UIColor colorWithWhite:1.0f alpha:0.5f] forState:UIControlStateDisabled];

}

-(void)setupVoiceBar:(UIView *)containerView closeButton:(UIButton *)closeButton recordButton:(UIButton *)recordButton backgroundView:(UIView *)backgroundView voiceLength:(CGFloat *)voiceLengthInSecond
{
    
}

- (void)customizeAMBubbleTableCell:(AMBubbleTableCell *)cell forCellType:(AMBubbleCellType)cellType atIndexPath:(NSIndexPath *)indexPath
{
    
}

#pragma mark - TableView Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.dataSource numberOfRows];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	AMBubbleCellType type = [self.dataSource cellTypeForRowAtIndexPath:indexPath];
	NSString* cellID = [NSString stringWithFormat:@"cell_%d", type];
	NSString* text = [self.dataSource textForRowAtIndexPath:indexPath];
    UIImage* msgImage;
    if ([self.dataSource respondsToSelector:@selector(msgImageForRowAtIndexPath:)]) {
        msgImage = [self.dataSource msgImageForRowAtIndexPath:indexPath];
    } else {
        msgImage = nil;
    }
	NSDate* date = [self.dataSource timestampForRowAtIndexPath:indexPath];
	AMBubbleTableCell* cell = [tableView dequeueReusableCellWithIdentifier:cellID];
	
	NSAssert(text != nil || date != nil, @"Text and Date cannot be both nil");
	
	UIImage* avatar;
	UIColor* color;
	
	if ([self.dataSource respondsToSelector:@selector(usernameColorForRowAtIndexPath:)]) {
		color = [self.dataSource usernameColorForRowAtIndexPath:indexPath];
	}
	if ([self.dataSource respondsToSelector:@selector(avatarForRowAtIndexPath:)]) {
		avatar = [self.dataSource avatarForRowAtIndexPath:indexPath];
	}

	if (cell == nil) {
		cell = [[AMBubbleTableCell alloc] initWithOptions:self.options
										  reuseIdentifier:cellID];

		if ([self.options[AMOptionsBubbleSwipeEnabled] boolValue]) {
			UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGesture:)];
			swipeGesture.direction = UISwipeGestureRecognizerDirectionLeft|UISwipeGestureRecognizerDirectionRight;
			[cell addGestureRecognizer:swipeGesture];
		}
		if ([self.options[AMOptionsMessageImagePressEnabled] boolValue]) {
			UITapGestureRecognizer *messageImagePressGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleMessageImagePressGesture:)];
            [cell setMessageImageGesture:messageImagePressGesture];
        }
        
        if ([self.delegate respondsToSelector:@selector(didTapErrorIconAtIndexPath:)]) {
            cell.errorIcon.tag = indexPath.row;
            [cell.errorIcon addTarget:self action:@selector(handleTapErrorIcon:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
	
	// iPad cells are set by default to 320 pixels, this fixes the quirk
	cell.contentView.frame = CGRectMake(cell.contentView.frame.origin.x,
										cell.contentView.frame.origin.y,
										self.tableView.frame.size.width,
										cell.contentView.frame.size.height);
	
	// Used by the gesture recognizer
	cell.tag = indexPath.row;
    cell.msgImageView.tag = indexPath.row;
	
	NSString* stringDate;
	if (type == AMBubbleCellTimestamp) {
		[self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];	// Jan 1, 2000
		[self.dateFormatter setTimeStyle:NSDateFormatterShortStyle];	// 1:23 PM
		stringDate = [self.dateFormatter stringFromDate:date];
		[cell setupCellWithType:type
					  withWidth:self.tableView.frame.size.width
					  andParams:@{ @"date": stringDate }];
	} else {
		[self.dateFormatter setDateFormat:@"HH:mm"];					// 13:23
		NSString* username;
		if ([self.dataSource respondsToSelector:@selector(usernameForRowAtIndexPath:)]) {
			username = [self.dataSource usernameForRowAtIndexPath:indexPath];
		}
		stringDate = [self.dateFormatter stringFromDate:date];
        if (msgImage) {
		[cell setupCellWithType:type
					  withWidth:self.tableView.frame.size.width
					  andParams:@{
		 @"text": text,
		 @"date": stringDate,
		 @"index": @(indexPath.row),
		 @"username": (username ? username : @""),
		 @"avatar": (avatar ? avatar: @""),
		 @"color": (color ? color: @""),
         @"msgImage": msgImage,
		 }];
        } else {
            [cell setupCellWithType:type
                          withWidth:self.tableView.frame.size.width
                          andParams:@{
                                      @"text": text,
                                      @"date": stringDate,
                                      @"index": @(indexPath.row),
                                      @"username": (username ? username : @""),
                                      @"avatar": (avatar ? avatar: @""),
                                      @"color": (color ? color: @""),
                                      }];
        }
	}
    
    if ([self.dataSource respondsToSelector:@selector(shouldShowErrorIconAtIndexPath:)]) {
        if ([self.dataSource shouldShowErrorIconAtIndexPath:indexPath]) {
            cell.errorIcon.hidden = NO;
        } else {
            cell.errorIcon.hidden = YES;
        }
    }
    
    [self customizeAMBubbleTableCell:cell forCellType:cell.cellType atIndexPath:indexPath];

	return cell;
}

- (void)handleTapErrorIcon:(UIButton *)sender
{
    NSInteger row = sender.tag;
    if ([self.delegate respondsToSelector:@selector(didTapErrorIconAtIndexPath:)]) {
        [self.delegate didTapErrorIconAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
    }
}

- (void)handleSwipeGesture:(UISwipeGestureRecognizer *)sender
{
	if ([self.delegate respondsToSelector:@selector(swipedCellAtIndexPath:withFrame:andDirection:)]) {
		[self.delegate swipedCellAtIndexPath:[NSIndexPath indexPathForRow:sender.view.tag inSection:0] withFrame:sender.view.frame andDirection:sender.direction];
	}
}

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)sender
{
    if ([self.delegate respondsToSelector:@selector(longPressedCellAtIndexPath:withFrame:)]) {
        if (sender.state == UIGestureRecognizerStateBegan) {
            [self.delegate longPressedCellAtIndexPath:[NSIndexPath indexPathForRow:sender.view.tag inSection:0] withFrame:sender.view.frame];
        }
    }
}

- (void)handleMessageImagePressGesture:(UITapGestureRecognizer *)sender
{
    if ([self.delegate respondsToSelector:@selector(pressedMessageImageAtIndexPath:)]) {
        [self.delegate pressedMessageImageAtIndexPath:[NSIndexPath indexPathForRow:sender.view.tag inSection:0]];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	AMBubbleCellType type = [self.dataSource cellTypeForRowAtIndexPath:indexPath];
	NSString* text = [self.dataSource textForRowAtIndexPath:indexPath];
	NSString* username = @"";
	
	if ([self.dataSource respondsToSelector:@selector(usernameForRowAtIndexPath:)]) {
		username = [self.dataSource usernameForRowAtIndexPath:indexPath];
	}
	
	if (type == AMBubbleCellTimestamp) {
		return [self.options[AMOptionsTimestampHeight] floatValue];
	}
    
    CGSize sizeImage = CGSizeMake(0, 0);
    if ([self.dataSource respondsToSelector:@selector(msgImageForRowAtIndexPath:)]) {
        UIImage *img = [self.dataSource msgImageForRowAtIndexPath:indexPath];
        if (img) {
            CGFloat width = 0, height = 0;
            if (img.size.width > img.size.height) {
                width = kMessageImageWidth;
                height = img.size.height / img.size.width * width;
            } else {
                height = kMessageImageHeight;
                width = img.size.width / img.size.height * height;
            }
            sizeImage = CGSizeMake(width, height);
        }
    } else {
        sizeImage = CGSizeMake(0, 0);
    }
    
    
    // Set MessageCell height.
	CGSize size;
	if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
#ifdef __IPHONE_7_0
		size = [text boundingRectWithSize:CGSizeMake(kMessageTextWidth, CGFLOAT_MAX)
								  options:NSStringDrawingUsesLineFragmentOrigin
							   attributes:@{NSFontAttributeName:self.options[AMOptionsBubbleTextFont]}
								  context:nil].size;
#endif
	} else {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
		size = [text sizeWithFont:self.options[AMOptionsBubbleTextFont]
				constrainedToSize:CGSizeMake(kMessageTextWidth, CGFLOAT_MAX)
					lineBreakMode:NSLineBreakByWordWrapping];
#pragma GCC diagnostic pop
	}
	
	CGSize usernameSize = CGSizeZero;
	
	if (![username isEqualToString:@""] && type == AMBubbleCellReceived) {
		if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
#ifdef __IPHONE_7_0
			usernameSize = [username boundingRectWithSize:CGSizeMake(kMessageTextWidth, CGFLOAT_MAX)
												  options:NSStringDrawingUsesLineFragmentOrigin
											   attributes:@{NSFontAttributeName:self.options[AMOptionsTimestampFont]}
												  context:nil].size;
#endif
		} else {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
			usernameSize = [username sizeWithFont:self.options[AMOptionsTimestampFont]
								constrainedToSize:CGSizeMake(kMessageTextWidth, CGFLOAT_MAX)
									lineBreakMode:NSLineBreakByWordWrapping];
#pragma GCC diagnostic pop
		}
	}
	
	// Account for either the bubble or accessory size
    return MAX(sizeImage.height + size.height + 17.0f + usernameSize.height,
			   [self.options[AMOptionsAccessorySize] floatValue] + [self.options[AMOptionsAccessoryMargin] floatValue]);
}

#pragma mark - Keyboard Handlers

- (void)handleKeyboardWillShow:(NSNotification *)notification
{
	[self resizeView:notification];
	[self scrollToBottomAnimated:YES];
}

- (void)handleKeyboardWillHide:(NSNotification *)notification
{
	[self resizeView:notification];	
}

- (void)resizeView:(NSNotification*)notification
{
	CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	UIViewAnimationCurve curve = [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
	double duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	
	CGFloat viewHeight = (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation) ? MIN(self.view.frame.size.width,self.view.frame.size.height) : MAX(self.view.frame.size.width,self.view.frame.size.height));
	CGFloat keyboardY = [self.view convertRect:keyboardRect fromView:nil].origin.y;
	CGFloat diff = keyboardY - viewHeight;
	
	// This check prevents an issue when the view is inside a UITabBarController
	if (diff > 0) {
		double fraction = diff/keyboardY;
		duration *= (1-fraction);
		keyboardY = viewHeight;
	}
	
	// Thanks to Raja Baz (@raja-baz) for the delay's animation fix.	
	CGFloat delay = 0.0f;
	CGRect beginRect = [[notification.userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
	diff = beginRect.origin.y - viewHeight;
	if (diff > 0) {
		double fraction = diff/beginRect.origin.y;
		delay = duration * fraction;
		duration -= delay;
	}
	
	void (^completition)(void) = ^{
		CGFloat inputViewFrameY = keyboardY - self.imageInput.frame.size.height;
		
		self.imageInput.frame = CGRectMake(self.imageInput.frame.origin.x,
										   inputViewFrameY,
										   self.imageInput.frame.size.width,
										   self.imageInput.frame.size.height);
		UIEdgeInsets insets = self.tableView.contentInset;
		insets.bottom = viewHeight - self.imageInput.frame.origin.y - kInputHeight;
		
		self.tableView.contentInset = insets;
		self.tableView.scrollIndicatorInsets = insets;
	};
	
	if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
#ifdef __IPHONE_7_0
		[UIView animateWithDuration:0.5
							  delay:0
			 usingSpringWithDamping:500.0f
			  initialSpringVelocity:0.0f
							options:UIViewAnimationOptionCurveLinear
						 animations:completition
						 completion:nil];
#endif
	} else {
		[UIView animateWithDuration:duration
							  delay:delay
							options:[AMBubbleGlobals animationOptionsForCurve:curve]
						 animations:completition
						 completion:nil];
	}
}

- (void)resizeTextViewByHeight:(CGFloat)delta
{
	int numLines = self.textView.contentSize.height / self.textView.font.lineHeight;

	self.textView.contentInset = UIEdgeInsetsMake((numLines >= 6 ? 4.0f : 0.0f),
                                                  0.0f,
                                                  (numLines >= 6 ? 4.0f : 0.0f),
                                                  0.0f);
	
	// Adjust table view's insets
	CGFloat viewHeight = (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) ? self.view.frame.size.width : self.view.frame.size.height;
    
	UIEdgeInsets insets = self.tableView.contentInset;
    insets.bottom = viewHeight - self.imageInput.frame.origin.y - kInputHeight;

	self.tableView.contentInset = insets;
	self.tableView.scrollIndicatorInsets = insets;

	// Slightly scroll the table
	[self.tableView setContentOffset:CGPointMake(0, self.tableView.contentOffset.y + delta) animated:YES];
}

- (void)handleTapGesture:(UIGestureRecognizer*)gesture
{
	[self.textView resignFirstResponder];
}

- (void)textViewDidChange:(UITextView *)textView
{
	[self.buttonSend setEnabled:([textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0)];

	CGFloat maxHeight = self.textView.font.lineHeight * 5;
	CGFloat textViewContentHeight = self.textView.contentSize.height;
	
	if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
		// Fixes the wrong content size computed by iOS7
		if (textView.text.UTF8String[textView.text.length-1] == '\n') {
			textViewContentHeight += textView.font.lineHeight;
		}
	}
	
    if ([@"" isEqualToString:textView.text]) {
    	self.tempTextView = [[UITextView alloc] init];
    	self.tempTextView.font = self.textView.font;
    	self.tempTextView.text = self.textView.text;
		
    	CGSize size = [self.tempTextView sizeThatFits:CGSizeMake(self.textView.frame.size.width, FLT_MAX)];
        textViewContentHeight  = size.height;
    }

	CGFloat delta = textViewContentHeight - self.previousTextFieldHeight;
	BOOL isShrinking = textViewContentHeight < self.previousTextFieldHeight;

	delta = (textViewContentHeight + delta >= maxHeight) ? 0.0f : delta;
	
	if(!isShrinking)
        [self resizeTextViewByHeight:delta];
    
    if(delta != 0.0f) {
        [UIView animateWithDuration:0.25f
                         animations:^{
                             UIEdgeInsets insets = self.tableView.contentInset;
                             insets.bottom = self.tableView.contentInset.bottom + delta;
                             self.tableView.contentInset = insets;
                             self.tableView.scrollIndicatorInsets = insets;
							 
                             [self scrollToBottomAnimated:NO];
							 
                             self.imageInput.frame = CGRectMake(0.0f,
                                                               self.imageInput.frame.origin.y - delta,
                                                               self.imageInput.frame.size.width,
                                                               self.imageInput.frame.size.height + delta);
                         }
                         completion:^(BOOL finished) {
                             if(isShrinking)
                                 [self resizeTextViewByHeight:delta];
                         }];
        
        self.previousTextFieldHeight = MIN(textViewContentHeight, maxHeight);
    }
	
	// This is a workaround for an iOS7 bug:
	// http://stackoverflow.com/questions/18070537/how-to-make-a-textview-scroll-while-editing
	if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
		if([textView.text hasSuffix:@"\n"]) {
			double delayInSeconds = 0.2;
			dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
			dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
				CGPoint bottomOffset = CGPointMake(0, self.textView.contentSize.height - self.textView.bounds.size.height);
				[self.textView setContentOffset:bottomOffset animated:YES];
			});
		}
	}
}

- (void)scrollToBottomAnimated:(BOOL)animated
{
    NSInteger bottomRow = [self.dataSource numberOfRows] - 1;
    if (bottomRow >= 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:bottomRow inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath
							  atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}

- (void)sendPressed:(id)sender
{
	[self.delegate didSendText:self.textView.text];
	[self.textView setText:@""];
	[self textViewDidChange:self.textView];
	[self resizeTextViewByHeight:self.textView.contentSize.height - self.previousTextFieldHeight];
    [self.buttonSend setEnabled:NO];
	[self scrollToBottomAnimated:YES];
}

- (void)reloadTableScrollingToBottom:(BOOL)scroll
{
	[self.tableView reloadData];
	if (scroll) {
		[self scrollToBottomAnimated:YES];
	}
}

- (NSDateFormatter*)dateFormatter
{
	if (_dateFormatter == nil) {
		_dateFormatter = [[NSDateFormatter alloc] init];
		[_dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale currentLocale] localeIdentifier]]];
	}
	return _dateFormatter;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self.tableView reloadData];
}

- (void)clickChooseImage:(id)sender {
    if ([self.delegate respondsToSelector:@selector(imageButtonClick:)]) {
        [self.delegate imageButtonClick:self];
    }
}

- (void)clickVoiceButton:(id)sender {
    self.voiceBar.hidden = NO;
}

- (void)clickVoiceCloseButton:(id)sender {
    self.voiceBar.hidden = YES;
}

- (void)voiceRecordButtonTouchUpInside:(id)sender {
    isRecording = YES;
    if (self.voiceRecorder.recordedTime < 0.2) {
        [self.voiceRecorder cancelRecording];
    } else {
        [self.voiceRecorder finishRecording];
    }
}

- (void)voiceRecordButtonTouchUpOutside:(id)sender {
    isRecording = NO;
    [self.voiceRecorder cancelRecording];
}

- (void)touchDownRecordButton:(id)sender {
    [self.voiceRecorder startRecording];
}

- (void)updateVoiceProgress:(NSTimer *)sender
{
    static CGFloat addUp = 1.0 / 1000;
    if (self.voiceProgressView.progress < 1.0) {
        self.voiceProgressView.progress += addUp;
    } else {
        // stop it
        isRecording = YES;
        [self.voiceRecorder finishRecording];
    }
    
}

-(void)didStartRecording
{
    isRecording = YES;
    self.recordTimer = nil;
    self.recordTimer = [[NSTimer alloc]initWithFireDate:[[NSDate alloc]initWithTimeIntervalSinceNow:0] interval:0.1 target:self selector:@selector(updateVoiceProgress:) userInfo:nil repeats:YES];
    self.recordTimer = [NSTimer scheduledTimerWithTimeInterval:(voiceLengthInSecond / 1000) target:self selector:@selector(updateVoiceProgress:) userInfo:nil repeats:YES];
}

-(void)didFinishRecording
{
    [self.recordTimer invalidate];
    self.voiceProgressView.progress = 0;
    NSLog(@"record finished");
}

-(void)didCancelRecording
{
    [self.recordTimer invalidate];
    self.voiceProgressView.progress = 0;
    NSLog(@"record cancelled");
}

@end
