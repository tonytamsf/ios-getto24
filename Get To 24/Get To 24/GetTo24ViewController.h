//
//  GetTo24ViewController.h
//  Get To 24
//
//  Created by Tony Tam on 1/4/14.
//  Copyright (c) 2014 Yama Llama. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GetTo24ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *buttonGiveUp;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property (weak, nonatomic) IBOutlet UIButton *skipButton;

@property (weak, nonatomic) IBOutlet UIButton *cardNE;
@property (weak, nonatomic) IBOutlet UIButton *cardSW;
@property (weak, nonatomic) IBOutlet UIButton *cardSE;
@property (weak, nonatomic) IBOutlet UIButton *cardNW;

@property (weak, nonatomic) IBOutlet UIButton *player1Button;
@property (weak, nonatomic) IBOutlet UIButton *player2Button;
@property (weak, nonatomic) IBOutlet UIButton *giveUpButton;

@property (weak, nonatomic) IBOutlet UILabel *player1Score;
@property (weak, nonatomic) IBOutlet UILabel *player2Score;

@property (weak, nonatomic) IBOutlet UIProgressView *gameCountdownProgress;

@property (weak, nonatomic) IBOutlet UILabel *player1NameLabel;

@property (weak, nonatomic) IBOutlet UILabel *player2NameLabel;

@end
