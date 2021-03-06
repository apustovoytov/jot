//
//  JotViewController.m
//  jot
//
//  Created by Laura Skelton on 4/30/15.
//
//

#import "JotViewController.h"
#import "JotDrawView.h"
#import "JotTextView.h"
#import "JotTextEditView.h"
#import "JotLabel.h"
#import <Masonry/Masonry.h>
#import "UIImage+Jot.h"
#import "JotDrawingContainer.h"

NSString const* kDrawView = @"DrawView";
NSString const* kLabels = @"Labels";
NSString const* kDate = @"Date";

@interface JotViewController () <UIGestureRecognizerDelegate, JotTextEditViewDelegate, JotDrawingContainerDelegate>

@property (nonatomic, strong) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchRecognizer;
@property (nonatomic, strong) UIRotationGestureRecognizer *rotationRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer *panRecognizer;
@property (nonatomic, strong, readwrite) JotDrawingContainer *drawingContainer;
@property (nonatomic, strong) JotDrawView *drawView;
@property (nonatomic, strong) JotTextEditView *textEditView;
@property (nonatomic, strong) JotTextView *textView;

@end

@implementation JotViewController

- (instancetype)init
{
    if ((self = [super init])) {
        
        _drawView = [JotDrawView new];
        _textEditView = [JotTextEditView new];
        _textEditView.delegate = self;
        _textView = [JotTextView new];
        _drawingContainer = [JotDrawingContainer new];
        self.drawingContainer.delegate = self;
		self.drawingContainer.discreteGridSize = 0; // no grid
        
        _font = self.textView.font;
        _fontSize = self.textView.fontSize;
		_textAlignment = self.textView.textAlignment;
        _textColor = self.textView.textColor;
        _textString = @"";
        _drawingColor = self.drawView.strokeColor;
        _drawingStrokeWidth = self.drawView.strokeWidth;
        _textEditingInsets = self.textEditView.textEditingInsets;
        _initialTextInsets = self.textView.initialTextInsets;
        _state = JotViewStateDefault;
		
		self.textEditView.textAlignment = NSTextAlignmentLeft;
        
        _pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
        self.pinchRecognizer.delegate = self;
        
        _rotationRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotateGesture:)];
        self.rotationRecognizer.delegate = self;
        
        _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
        self.panRecognizer.delegate = self;
        
        _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
        self.tapRecognizer.delegate = self;
    }
    
    return self;
}

- (void)dealloc
{
    self.textEditView.delegate = nil;
    self.drawingContainer.delegate = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    self.drawingContainer.clipsToBounds = YES;
    
    [self.view addSubview:self.drawingContainer];
    [self.drawingContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    [self.drawingContainer addSubview:self.drawView];
    [self.drawView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.drawingContainer);
    }];
    
    [self.drawingContainer addSubview:self.textView];
    [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.drawingContainer);
    }];
    
    [self.view addSubview:self.textEditView];
    [self.textEditView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    [self.drawingContainer addGestureRecognizer:self.tapRecognizer];
    [self.drawingContainer addGestureRecognizer:self.panRecognizer];
    [self.drawingContainer addGestureRecognizer:self.rotationRecognizer];
    [self.drawingContainer addGestureRecognizer:self.pinchRecognizer];
}

#pragma mark - Properties

- (void)setState:(JotViewState)state
{
    if (_state != state) {
        _state = state;
        
        self.textView.hidden =
        self.textEditView.isEditing = (state == JotViewStateEditingText);
        
        if (state == JotViewStateEditingText
            && [self.delegate respondsToSelector:@selector(jotViewController:isEditingText:)]) {
            [self.delegate jotViewController:self isEditingText:YES];
        }
		
		if (state != JotViewStateText && state != JotViewStateEditingText) {
			[self.textView deselectLabel];
		}
        
        self.drawingContainer.multipleTouchEnabled =
        self.tapRecognizer.enabled =
        self.panRecognizer.enabled =
        self.pinchRecognizer.enabled =
        self.rotationRecognizer.enabled = (state == JotViewStateText);
    }
}

- (void)setTextString:(NSString *)textString
{
	_textString = textString;
	if (![self.textView.textString isEqualToString:textString]) {
		self.textView.textString = textString;
	}
	if (![self.textEditView.textString isEqualToString:textString]) {
		self.textEditView.textString = textString;
	}
}

- (void)setFont:(UIFont *)font
{
	_font = font;
	self.textView.font =
	self.textEditView.font = font;
}

- (void)setFontSize:(CGFloat)fontSize
{
	_fontSize = fontSize;
	self.textView.fontSize =
	self.textEditView.fontSize = fontSize;
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment
{
	_textAlignment = textAlignment;
	self.textView.textAlignment =
	self.textEditView.textAlignment = textAlignment;
}

- (void)setTextColor:(UIColor *)textColor
{
	_textColor = textColor;
	self.textView.textColor =
	self.textEditView.textColor = textColor;
}

- (void)setInitialTextInsets:(UIEdgeInsets)initialTextInsets
{
	_initialTextInsets = initialTextInsets;
	self.textView.initialTextInsets = initialTextInsets;
}

- (void)setTextEditingInsets:(UIEdgeInsets)textEditingInsets
{
	_textEditingInsets = textEditingInsets;
	self.textEditView.textEditingInsets = textEditingInsets;
}

- (void)setFitOriginalFontSizeToViewWidth:(BOOL)fitOriginalFontSizeToViewWidth
{
	_fitOriginalFontSizeToViewWidth = fitOriginalFontSizeToViewWidth;
	self.textView.fitOriginalFontSizeToViewWidth = fitOriginalFontSizeToViewWidth;
	if (fitOriginalFontSizeToViewWidth) {
		self.textEditView.textAlignment = self.textAlignment;
	} else {
		self.textEditView.textAlignment = NSTextAlignmentLeft;
	}
}

- (void)setClipBoundsToEditingInsets:(BOOL)clipBoundsToEditingInsets
{
	_clipBoundsToEditingInsets = clipBoundsToEditingInsets;
	self.textEditView.clipBoundsToEditingInsets = clipBoundsToEditingInsets;
}

- (void)setDrawingColor:(UIColor *)drawingColor
{
    if (_drawingColor != drawingColor) {
        _drawingColor = drawingColor;
        self.drawView.strokeColor = drawingColor;
    }
}

- (void)setDrawingStrokeWidth:(CGFloat)drawingStrokeWidth
{
    if (_drawingStrokeWidth != drawingStrokeWidth) {
        _drawingStrokeWidth = drawingStrokeWidth;
        self.drawView.strokeWidth = drawingStrokeWidth;
    }
}

- (void)setDrawingConstantStrokeWidth:(BOOL)drawingConstantStrokeWidth
{
    if (_drawingConstantStrokeWidth != drawingConstantStrokeWidth) {
        _drawingConstantStrokeWidth = drawingConstantStrokeWidth;
        self.drawView.constantStrokeWidth = drawingConstantStrokeWidth;
    }
}

- (void)setDrawingLineDashed:(BOOL)drawingLineDashed
{
	_drawingLineDashed = drawingLineDashed;
	self.drawView.dashedLine = drawingLineDashed;
}

- (void)setDrawingLineRightAngle:(BOOL)drawingLineRightAngle
{
	_drawingLineRightAngle = drawingLineRightAngle;
	self.drawView.rightAngleLinesOnly = drawingLineRightAngle;
}

- (void)setDrawingLineDiscreteGridSize:(NSUInteger)drawingLineDiscreteGridSize
{
	_drawingLineDiscreteGridSize = drawingLineDiscreteGridSize;
	self.drawingContainer.discreteGridSize = drawingLineDiscreteGridSize;
}

#pragma mark - Undo

- (void)clearAll
{
    [self clearDrawing];
    [self clearText];
}

- (void)clearDrawing
{
    [self.drawView clearDrawing];
}

- (void)undoDrawing
{
	[self.drawView undo];
}

- (void)redoDrawing
{
	[self.drawView redo];
}

- (void)clearText
{
    self.textString = @"";
    [self.textView clearAll];
}

- (void)deleteSelectedLabel {
	[self.textView deleteSelectedLabel];
}

#pragma mark - Output UIImage

- (UIImage *)drawOnImage:(UIImage *)image
{
    UIImage *drawImage = [self.drawView drawOnImage:image];
    
    return [self.textView drawTextOnImage:drawImage];
}

- (UIImage *)renderImage
{
    return [self renderImageWithScale:1.f];
}

- (UIImage *)renderImageOnColor:(UIColor *)color
{
    return [self renderImageWithScale:1.f onColor:color];
}

- (UIImage *)renderImageWithScale:(CGFloat)scale
{
    return [self renderImageWithSize:CGSizeMake(CGRectGetWidth(self.drawingContainer.frame) * scale,
                                           CGRectGetHeight(self.drawingContainer.frame) * scale)];
}

- (UIImage *)renderImageWithScale:(CGFloat)scale onColor:(UIColor *)color
{
    return [self renderImageWithSize:CGSizeMake(CGRectGetWidth(self.drawingContainer.frame) * scale,
                                                CGRectGetHeight(self.drawingContainer.frame) * scale)
                             onColor:color];
}

- (UIImage *)renderImageWithSize:(CGSize)size
{
    UIImage *renderDrawingImage = [self.drawView renderDrawingWithSize:size];
    
    return [self.textView drawTextOnImage:renderDrawingImage];
}

- (UIImage *)renderImageWithSize:(CGSize)size onColor:(UIColor *)color
{
    UIImage *colorImage = [UIImage jotImageWithColor:color size:size];
    
    UIImage *renderDrawingImage = [self.drawView drawOnImage:colorImage];
    
    return [self.textView drawTextOnImage:renderDrawingImage];
}

#pragma mark - Gestures

- (void)handleTapGesture:(UIGestureRecognizer *)recognizer
{
    if (self.state == JotViewStateText) {
		// a tap during text
		CGPoint touch = [recognizer locationOfTouch:0 inView:self.textView];
		JotLabel *label = [self.textView labelAtPosition:touch];
		if (label) {
			// a tap on a label
			if (label.selected) {
				// a tap on a label already selected
				self.state = JotViewStateEditingText;
			}
			else {
				// a tap on a label not selected
				[self.textView selectLabelAtPosition:touch];
			
				if ([self.delegate respondsToSelector:@selector(jotViewController:didSelectLabel:)]) {
					[self.delegate jotViewController:self didSelectLabel:[label serialize]];
				}
			}
			self.textEditView.textString = label.text;
		}
		else {
			// a tap on a blank space
			label = [self.textView addLabelAtPosition:touch];
			self.textEditView.textString = @"";
			self.state = JotViewStateEditingText;
		}
		self.textEditView.font = label.font;
		self.textEditView.textColor = label.textColor;
    }
}

- (void)handlePanGesture:(UIGestureRecognizer *)recognizer
{
    [self.textView handlePanGesture:recognizer];
}

- (void)handlePinchGesture:(UIGestureRecognizer *)recognizer
{
    [self.textView handlePinchOrRotateGesture:recognizer];
}

- (void)handleRotateGesture:(UIGestureRecognizer *)recognizer
{
	[self.textView handlePinchOrRotateGesture:recognizer];
}

#pragma mark - JotDrawingContainer Delegate

- (BOOL)jotDrawingContainerShouldDiscretise {
	return self.state == JotViewStateDrawLines;
}

- (void)jotDrawingContainerTouchBeganAtPoint:(CGPoint)touchPoint
{
    if (self.state == JotViewStateDrawing) {
        [self.drawView drawTouchBeganAtPoint:touchPoint];
    }
	else if (self.state == JotViewStateDrawLines) {
		[self.drawView drawLineBeganAtPoint:touchPoint];
	}
}

- (void)jotDrawingContainerTouchMovedToPoint:(CGPoint)touchPoint
{
    if (self.state == JotViewStateDrawing) {
        [self.drawView drawTouchMovedToPoint:touchPoint];
    }
	else if (self.state == JotViewStateDrawLines) {
		[self.drawView drawLineMovedToPoint:touchPoint];
	}
}

- (void)jotDrawingContainerTouchEndedAtPoint:(CGPoint)touchPoint
{
    if (self.state == JotViewStateDrawing) {
        [self.drawView drawTouchEndedAtPoint:touchPoint];
    }
	else if (self.state == JotViewStateDrawLines) {
		[self.drawView drawLineEndedAtPoint:touchPoint];
	}
}

#pragma mark - UIGestureRecognizer Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        return YES;
    }
    return NO;
}

#pragma mark - JotTextEditView Delegate

- (void)jotTextEditViewFinishedEditingWithNewTextString:(NSString *)textString
{
    if (self.state == JotViewStateEditingText) {
        self.state = JotViewStateText;
    }
    
    self.textString = textString;
    
    if ([self.delegate respondsToSelector:@selector(jotViewController:isEditingText:)]) {
        [self.delegate jotViewController:self isEditingText:NO];
    }
}

#pragma mark - Orientation

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
	
	self.drawView.alpha = 0;

	[coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		[self.drawView refreshBitmap];
		[UIView animateWithDuration:0.2f animations:^{
			self.drawView.alpha = 1;
		}];
	}];
}

#pragma mark - Serialization

- (NSDictionary*)serialize {
	NSDictionary *drawView = [self.drawView serialize];
	NSArray *labels = [self.textView serialize];
	return @{kDrawView: drawView,
			 kLabels: labels,
			 kDate: [NSDate date]};
}

- (void)unserialize:(NSDictionary*)dictionary {
	if (dictionary[kDrawView]) {
		[self.drawView unserialize:dictionary[kDrawView]];
	}
	if (dictionary[kLabels]) {
		[self.textView unserialize:dictionary[kLabels]];
	}
}


@end
