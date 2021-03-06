//
//  GameViewController.m
//  Tababooboo
//
//  Created by Flora on 12/28/13.
//  Copyright (c) 2013 Tababooboo. All rights reserved.
//

#import "GameViewController.h"
#import "Constants.h"
#import "Game.h"
#import "Word.h"
#import "WordStore.h"
#import "RandomizedWordSequence.h"

@interface wordResultSwipe : UISwipeGestureRecognizer
@property NSString *word;
@property bool correct;
@end

@implementation wordResultSwipe

- (id)init
{
    self = [super init];
    if (self) {
        // Custom initialization
    }
    return self;
}

@end

@interface GameViewController ()

/// Store of all known taboo words
@property WordStore                 *wordStore;

/// Current sequence. This should be used for retrieving the
/// next words to display.
@property RandomizedWordSequence    *currentSequence;

/// The word currently being displayed
@property Word                      *currentWord;

@property wordResultSwipe          *correctSwipe;
@property wordResultSwipe          *skipSwipe;

@property UIImage                  *screenShot;
@property UIImageView              *imageView;

@property UILabel                  *correctLabel;

@end

@implementation GameViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.navigationItem.hidesBackButton = YES;
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.millisecondsElapsed = 0;
    self.timer = [NSTimer scheduledTimerWithTimeInterval: TimerFrequencyMilliseconds/1000.0f target:self selector:@selector(updateTimer:) userInfo:nil repeats:YES];
    [self viewNextWord];
    
#if DEBUG
    // Check for ambiguous layouts.
    if ([self.uiTimer hasAmbiguousLayout]) {
        NSLog(@"WARNING: uiTimer has ambiguous layout.");
        [self.uiTimer exerciseAmbiguityInLayout];
    }
    if ([self.wordLabel hasAmbiguousLayout]) {
        NSLog(@"WARNING: wordLabel has ambiguous layout.");
        [self.wordLabel exerciseAmbiguityInLayout];
    }
    if ([self.prohibitedWordContainer hasAmbiguousLayout]) {
        NSLog(@"WARNING: prohibited words has amibiguous layout");
        [self.prohibitedWordContainer exerciseAmbiguityInLayout];
    }
    if ([self.buttonCont hasAmbiguousLayout]) {
        NSLog(@"WARNING: button cont has amibiguous layout");
        [self.buttonCont exerciseAmbiguityInLayout];
    }
#endif
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.wordStore = [[WordStore alloc] init];
    
    // Initializes the word store by reading words in from the json file
    // included with the app.
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"words" ofType:@"json"];
    [self.wordStore loadFromFile:filePath];
    
    // Load the word sequence, if one exists.
    NSString *directory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [directory stringByAppendingPathComponent:WordSequenceFilename];
    NSDictionary *seqDictionary = nil;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        seqDictionary = [[NSDictionary alloc] initWithContentsOfFile:path];
    }
    if (seqDictionary) {
        // There's previous sequence data saved on the filesystem. Use that to initialize the word sequence.
        NSLog(@"Loading word sequence from %@.plist\n", WordSequenceFilename);
        self.currentSequence = [[RandomizedWordSequence alloc] initFromDictionary:seqDictionary wordStore:self.wordStore];
    } else {
        // We have no previous sequence data, so start a new sequence.
        NSLog(@"No serialized word sequence available. Starting new word sequence.\n");
        self.currentSequence = [[RandomizedWordSequence alloc] initWithWordStore:self.wordStore];
    }
    
    self.view.backgroundColor = PrimaryBackgroundColor;
    [self addTimer];
    [self setupWordLabels];
    [self setupSwipes];
    //[self setupButtons];
}

- (void)updateTimer:(NSTimer *)timer
{
    if (1000 * self.secondsPerRound - self.millisecondsElapsed > 0) {
        self.millisecondsElapsed += TimerFrequencyMilliseconds;
        self.uiTimer.time = self.millisecondsElapsed;
    }
    else {
        NSLog(@"Round ended.");
        [timer invalidate];
        timer = nil;
        [self.delegate switchToRoundResultsController];
    }
}

- (void)addTimer
{
    self.uiTimer = [[UITimer alloc] init];
    self.uiTimer.maxTime = self.secondsPerRound * 1000;
    self.uiTimer.backgroundColor = TimerBackgroundColor;
    self.uiTimer.foregroundColor = TimerProgressColor;
    self.uiTimer.translatesAutoresizingMaskIntoConstraints = NO;
    self.uiTimer.layer.zPosition = MAXFLOAT;
    [self.view addSubview:self.uiTimer];
    [self center:self.uiTimer];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.uiTimer
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeHeight
                                                         multiplier:0
                                                           constant:TimerHeightPixels]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[timer]" options:0 metrics:nil views: @{@"timer": self.uiTimer}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[timer]|" options:0 metrics:nil views: @{@"timer": self.uiTimer}]];
}

- (void)setupWordLabels
{
    // Construct the primary word label for the guess word.
    self.wordLabel = [[UILabel alloc] init];
    self.wordLabel.text = @"";
    self.wordLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.wordLabel.textAlignment = NSTextAlignmentCenter;
    self.wordLabel.adjustsFontSizeToFitWidth = YES;
    self.wordLabel.font = GuessWordFont;
    self.wordLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    self.wordLabel.numberOfLines = 2;
    [self.view addSubview:self.wordLabel];
    
    [self center:self.wordLabel];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[w]-|" options:0 metrics:nil views:@{@"w": self.wordLabel}]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.wordLabel
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.uiTimer
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1.0
                                                           constant:10]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.wordLabel
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeHeight
                                                         multiplier:GuessWordHeightAsPct
                                                           constant:0]];
    // Setup the container for the prohibited words. All labels will be relative to this.
    UIView *prohibitedContainer = [[UIView alloc] init];
    prohibitedContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:prohibitedContainer];
    
    [self center:prohibitedContainer];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:prohibitedContainer
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeHeight
                                                         multiplier:ProhibitedWordsHeightAsPct
                                                           constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:prohibitedContainer
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.wordLabel
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1.0
                                                           constant:10]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:prohibitedContainer
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.wordLabel
                                                          attribute:NSLayoutAttributeWidth
                                                         multiplier:0.70
                                                           constant:0]];
    
    // Create the prohibited word labels
    NSMutableArray *prohibitedWordLabels = [[NSMutableArray alloc] initWithCapacity:ProhibitedWordCount];
    
    UILabel *firstLabel = nil;
    UILabel *prevLabel = nil;
    
    for (int i = 0; i < ProhibitedWordCount; ++i) {
        UILabel *label = [[UILabel alloc] init];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.adjustsFontSizeToFitWidth = YES;
        label.font = ProhibitedWordsFont;
        label.textColor = ProhibitedWordsColor;
        label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        label.textAlignment = NSTextAlignmentCenter;
        label.text = @"";
        [prohibitedContainer addSubview:label];
        [prohibitedContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[w]|" options:0 metrics:nil views:@{@"w": label}]];
        [prohibitedContainer addConstraint:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:prohibitedContainer attribute:NSLayoutAttributeHeight multiplier:1.0f/ProhibitedWordCount constant:-1]];
        
        if (!prevLabel) {
            firstLabel = label;
            // This is the first label. We need to make a constraint against
            // the top of its container.
            [prohibitedContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[w]" options:0 metrics:nil views:@{@"w": label}]];
        } else {
            // There was a label before us. We need to add constraints to
            // position this label in relation to that label.
            [prohibitedContainer addConstraint:[NSLayoutConstraint constraintWithItem:label
                                                                            attribute:NSLayoutAttributeTop
                                                                            relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                               toItem:prevLabel
                                                                            attribute:NSLayoutAttributeBottom
                                                                           multiplier:1.0
                                                                             constant:0]];
            // This label must also be the same height as the previous label.
            [prohibitedContainer addConstraint:[NSLayoutConstraint constraintWithItem:label
                                                                            attribute:NSLayoutAttributeHeight
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:firstLabel
                                                                            attribute:NSLayoutAttributeHeight
                                                                           multiplier:1.0
                                                                             constant:0]];
            // We'd also like the vertical trailing space to be equal to the height.
        }
        
        prohibitedWordLabels[i] = label;
        prevLabel = label;
    }
    
    // For the last label, we want it to be flush against the bottom of the container
    [prohibitedContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[w]|" options: 0 metrics:nil views:@{@"w": prevLabel}]];
     
    self.prohibitedWordContainer = prohibitedContainer;
    self.prohibitedWordLabels = prohibitedWordLabels;
}

- (void)setupSwipes
{
    self.correctSwipe = [[wordResultSwipe alloc] initWithTarget:self action:@selector(swipedScreen:)];
    self.correctSwipe.direction = (UISwipeGestureRecognizerDirectionDown);
    self.correctSwipe.word = self.wordLabel.text;
    self.correctSwipe.correct = true;
    [self.view addGestureRecognizer:self.correctSwipe];
    
    
    self.skipSwipe = [[wordResultSwipe alloc] initWithTarget:self action:@selector(swipedScreen:)];
    self.skipSwipe .direction = (UISwipeGestureRecognizerDirectionUp);
    self.skipSwipe.word = self.wordLabel.text;
    self.skipSwipe.correct = false;
    [self.view addGestureRecognizer:self.skipSwipe];
}

// Helper function that will crop the timer image out of the way.
- (UIImage *)croppIngimageByImageName:(UIImage *)imageToCrop toRect:(CGRect)rect
{
    //CGRect CropRect = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height+15);
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([imageToCrop CGImage], rect);
    
    UIImage *cropped = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return cropped;
}

- (void)addCorrectLabel
{
    //Sets the +1 for a correct answer ready for use
    NSInteger widthOfLabel = 100;
    NSInteger heightOfLabel = 100;
    
    NSInteger widthOfScreen = self.view.bounds.size.width;
    NSInteger heightOfScreen = self.view.bounds.size.height;
    
    self.correctLabel = [[UILabel alloc] init];
    self.correctLabel.frame = CGRectMake(widthOfScreen/2-widthOfLabel/2, heightOfScreen/2-heightOfLabel/2,
                                         widthOfLabel, heightOfLabel);
    self.correctLabel.text = @"+1";
    self.correctLabel.textColor=PrimaryHeaderColor;
    [self.correctLabel setFont:[UIFont fontWithName:@"Arial Black" size:80]];
    [self.correctLabel setFont:[UIFont systemFontOfSize:80]];
    [self.view addSubview:self.correctLabel];
    self.correctLabel.layer.zPosition = MAXFLOAT;
    // If correct show a label with a +1
    [UIView animateWithDuration:1.0f delay:0.0f options:0
                     animations:^{self.correctLabel.alpha = 0.0;}
                     completion:^(BOOL finished) {[self.correctLabel removeFromSuperview];}];
}

- (void)swipedScreen:(wordResultSwipe*)recognizer
{
    UIGraphicsBeginImageContext(self.view.bounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.view.layer renderInContext:context];
    self.screenShot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGFloat notificationBarHeight = 5;
    CGRect cropRect = CGRectMake(0, notificationBarHeight, self.view.bounds.size.width, self.view.bounds.size.height- notificationBarHeight);
    self.screenShot = [self croppIngimageByImageName:self.screenShot toRect:cropRect];
    
    self.imageView = [[UIImageView alloc] initWithImage:self.screenShot];
    self.imageView.frame = CGRectMake(0, notificationBarHeight, self.view.bounds.size.width, self.view.bounds.size.height);
    [self.view addSubview:self.imageView];
    
    NSInteger transitioningLocation;
    // If correct the screenshot swipes up.
    if(recognizer.correct)
    {
        transitioningLocation = self.view.frame.size.height;
        [self addCorrectLabel];
    }
    else
    {
        transitioningLocation = -self.view.frame.size.height;
    }
    
    [UIView animateWithDuration:0.75 delay:0 options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.imageView.frame = CGRectMake(0, transitioningLocation, self.imageView.frame.size.width, self.imageView.frame.size.height);
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                         }
                     }];
    
    Game* game = [self.delegate getGame];
    [game updateRound:self.currentWord :recognizer.correct];
    [self viewNextWord];
}

/*
- (void)setupButtons
{
    // Setup the UI view that contains the buttons.
    UIView *buttonContainer = [[UIView alloc] init];
    buttonContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:buttonContainer];
    
    [self center:buttonContainer];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[buttons]|" options:0 metrics:nil views:@{@"buttons": buttonContainer}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[buttons]|" options:0 metrics:nil views:@{@"buttons": buttonContainer}]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:buttonContainer
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeHeight
                                                         multiplier:ButtonsHeightAsPct
                                                           constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.prohibitedWordContainer
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:buttonContainer
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0
                                                           constant: -1 * MinimumButtonContainerTopMargin]];
    
    self.buttonCont = buttonContainer;
    
    self.correctButton = [wordResultButton buttonWithType:UIButtonTypeRoundedRect];
    self.correctButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.correctButton setTitle:@"Correct" forState:UIControlStateNormal];
    self.correctButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.correctButton.backgroundColor = PrimaryButtonBackgroundColor;
    [self.correctButton setTitleColor:PrimaryHeaderColor forState:UIControlStateNormal];
    // TODO: customize UI components (styling for buttons, etc)
    self.correctButton.word = self.wordLabel.text;
    self.correctButton.correct = true;
    [self.correctButton addTarget:self action:@selector(addWordResultToRound:) forControlEvents:UIControlEventTouchUpInside];
    [buttonContainer addSubview:self.correctButton];
    
    self.skipButton = [wordResultButton buttonWithType:UIButtonTypeRoundedRect];
    self.skipButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.skipButton setTitle:@"Skip" forState:UIControlStateNormal];
    self.skipButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.skipButton.backgroundColor = PrimaryButtonBackgroundColor;
    [self.skipButton setTitleColor:PrimaryHeaderColor forState:UIControlStateNormal];
    // TODO: customize UI components (styling for buttons, etc)
    self.skipButton.word = self.wordLabel.text;
    self.skipButton.correct = false;
    [self.skipButton addTarget:self action:@selector(addWordResultToRound:) forControlEvents:UIControlEventTouchUpInside];
    [buttonContainer addSubview:self.skipButton];
    
    [buttonContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[b]|" options:0 metrics:nil views:@{@"b": self.correctButton}]];
    [buttonContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[c]-[s]|" options:0 metrics:nil views:@{@"c": self.correctButton, @"s":self.skipButton}]];
    [buttonContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[b]|" options:0 metrics:nil views:@{@"b": self.skipButton}]];
    [buttonContainer addConstraint:[NSLayoutConstraint constraintWithItem:self.correctButton
                                                                attribute:NSLayoutAttributeWidth
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.skipButton
                                                                attribute:NSLayoutAttributeWidth
                                                               multiplier:1.0
                                                                 constant:0]];
}
*/

- (Word *)nextWord
{
    if (![self.currentSequence hasNext]) {
        [self.currentSequence restart];
    }
    
    Word *next = [self.currentSequence next];
    self.currentWord = next;
    
    return next;
}

- (void) viewNextWord
{
    Word *nextWord = [self nextWord];
    self.wordLabel.text = [nextWord formattedWord];
    
    NSArray *prohibitedWords = [nextWord.prohibitedWords allObjects];
    for (int i = 0; i < ProhibitedWordCount; ++i) {
        UILabel *label = self.prohibitedWordLabels[i];
        label.text = prohibitedWords[i];
    }
}

/*
- (void)addWordResultToRound:(id)sender
{
    wordResultButton *buttonClicked = (wordResultButton *)sender;
    Game* game = [self.delegate getGame];
    [game updateRound:self.currentWord :buttonClicked.correct];
    [self viewNextWord];
}
 */

- (void) center:(UIView *)view
{
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:view
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0
                                                           constant:0]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) preserveData
{
    NSString *directory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [directory stringByAppendingPathComponent:WordSequenceFilename];
    NSDictionary *toSave = [self.currentSequence toDict];
    NSError *error;
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:toSave
                                                              format:NSPropertyListXMLFormat_v1_0
                                                             options:0
                                                               error:&error];
    // Save the data to the file
    NSError *err;
    if (![data writeToFile:path options:NSAtomicWrite error:&err]) {
        NSLog(@"Write to %@ failed with error %@\n", path, err);
    } else {
        NSLog(@"Saved sequence data to plist.");
    }
}

@end
