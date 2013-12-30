//
//  GameViewController.h
//  Tababooboo
//
//  Created by Flora on 12/28/13.
//  Copyright (c) 2013 Tababooboo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITimer.h"

@protocol GameViewControllerDelegate <NSObject>

@end

@interface GameViewController : UIViewController


void addTimer();
void updateTimer();

@property IBOutlet UIButton *correctButton;
@property IBOutlet UIButton *skipButton;
@property IBOutlet NSTimer *timer;

@property UITimer *uiTimer;

@property int secondsPerRound;
@property int millisecondsElapsed;
@property (weak, nonatomic) id<GameViewControllerDelegate> delegate;

@end