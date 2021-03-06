//
//  Constants.m
//  Tababooboo
//
//  Created by Jackson Owens on 12/28/13.
//  Copyright (c) 2013 Tababooboo. All rights reserved.
//

#import "Constants.h"

UIColor *PrimaryHeaderColor;
UIColor *PrimaryBackgroundColor;
UIColor *PrimaryButtonBackgroundColor;
UIColor *PrimarySelectedButtonBackgroundColor;

UIColor *SecondaryHeaderColor;

UIColor *TimerBackgroundColor;
UIColor *TimerProgressColor;

UIFont  *ProhibitedWordsFont;
UIColor *ProhibitedWordsColor;

UIFont  *GuessWordFont;

UIColor *CorrectWordColor;
UIColor *SkippedWordColor;

NSString    *WordSequenceFilename = @"WordSequenceState.json";

int      InfiniteFontSize = 200;
int      TimerFrequencyMilliseconds = 50;
int      TimerHeightPixels = 4;

float    GuessWordHeightAsPct = 0.20f;
float    ProhibitedWordsHeightAsPct = 0.5;
int      MinimumSpacingBetweenProhibitedWordsPixels = 10;
float    ButtonsHeightAsPct = 0.10f;
int      MinimumButtonContainerTopMargin = 10;

float    TeamNameHeightAsPct = 0.15f;
float    ResultWordsHeightAsPct = 0.6;

int      ProhibitedWordCount = 5;

@implementation Constants

+ (void) load {
    PrimaryHeaderColor = [UIColor colorWithRed:129/255.0f green:17/255.0f blue:117/255.0f alpha:1.0f];
    PrimaryBackgroundColor = [UIColor whiteColor];
    PrimaryButtonBackgroundColor = [UIColor clearColor];
    PrimarySelectedButtonBackgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    
    SecondaryHeaderColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    
    TimerBackgroundColor = [UIColor colorWithWhite:0.90 alpha:1.0];
    TimerProgressColor = [UIColor colorWithRed:129/255.0f green:17/255.0f blue:117/255.0f alpha:1.0f];
    
    ProhibitedWordsFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:28];
    ProhibitedWordsColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    
    GuessWordFont = [UIFont systemFontOfSize:40];
    
    CorrectWordColor = [UIColor blackColor];
    SkippedWordColor = [UIColor colorWithWhite:0.6 alpha:1.0];
}

@end
