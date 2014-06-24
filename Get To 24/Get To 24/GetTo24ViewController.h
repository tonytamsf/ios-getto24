//
//  GetTo24ViewController.h
//  Get To 24
//
//  Created by Tony Tam on 1/4/14.
//  Copyright (c) 2014 Yama Llama. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AudioUtil.h"

@interface GetTo24ViewController : UIViewController

@property (strong, nonatomic) AudioUtil *util;
@property (strong, nonatomic) AudioUtil *backGround;

@property (weak, nonatomic) IBOutlet UIButton *cardNE;
@property (weak, nonatomic) IBOutlet UIButton *cardSW;
@property (weak, nonatomic) IBOutlet UIButton *cardSE;
@property (weak, nonatomic) IBOutlet UIButton *cardNW;

@property (weak, nonatomic) IBOutlet UIButton *player1Button;
@property (weak, nonatomic) IBOutlet UIButton *player2Button;

@property (weak, nonatomic) IBOutlet UILabel *player1Score;
@property (weak, nonatomic) IBOutlet UILabel *player2Score;

@property (weak, nonatomic) IBOutlet UILabel *player1NameLabel;

@property (weak, nonatomic) IBOutlet UILabel *player2NameLabel;

@property (weak, nonatomic) IBOutlet UILabel *labelNWleft;
@property (weak, nonatomic) IBOutlet UILabel *labelNWright;
@property (weak, nonatomic) IBOutlet UILabel *labelNEleft;
@property (weak, nonatomic) IBOutlet UILabel *labelNEright;
@property (weak, nonatomic) IBOutlet UILabel *labelSWleft;
@property (weak, nonatomic) IBOutlet UILabel *labelSWright;
@property (weak, nonatomic) IBOutlet UILabel *labelSEright;
@property (weak, nonatomic) IBOutlet UILabel *labelSEleft;

@property (weak, nonatomic) IBOutlet UILabel *labelAnswer;
@property (weak, nonatomic) IBOutlet UILabel *labelAnswer2;
@property (weak, nonatomic) IBOutlet UIButton *buttonPlus2;
@property (weak, nonatomic) IBOutlet UIButton *buttonMinus2;
@property (weak, nonatomic) IBOutlet UIButton *buttonMultiplication2;
@property (weak, nonatomic) IBOutlet UIButton *buttonDivision2;
@property (weak, nonatomic) IBOutlet UILabel *labelTime;
@property (weak, nonatomic) IBOutlet UILabel *labelTimeStatic;
@property (weak, nonatomic) IBOutlet UILabel *labelTime1;

@property (weak, nonatomic) IBOutlet UILabel *labelTimeStatic1;
@property (strong, nonatomic) IBOutlet UISwipeGestureRecognizer *swipeGesture1;
@property (weak, nonatomic) IBOutlet UILabel *labelBackground2;
@property (weak, nonatomic) IBOutlet UILabel *labelBackground1;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentLevels;
@property (strong, nonatomic) IBOutlet UISwipeGestureRecognizer *swipeGestureGiveUp;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewCenter;

@property (weak, nonatomic) IBOutlet UILabel *labelMiddleInfo;

@property (weak, nonatomic) IBOutlet UIButton *soundButton;

@property (strong, nonatomic) IBOutlet UISwipeGestureRecognizer *swipeGesture;
@end
