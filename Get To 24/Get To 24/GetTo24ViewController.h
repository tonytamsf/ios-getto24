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
@property (weak, nonatomic) IBOutlet UILabel *operatorNWNE;
@property (weak, nonatomic) IBOutlet UILabel *operatorNESE;
@property (weak, nonatomic) IBOutlet UILabel *operatorSWSE;
@property (weak, nonatomic) IBOutlet UILabel *operatorNWSW;

@property (weak, nonatomic) IBOutlet UIButton *player1Button;
@property (weak, nonatomic) IBOutlet UIButton *player2Button;

@property (weak, nonatomic) IBOutlet UILabel *player1Score;
@property (weak, nonatomic) IBOutlet UILabel *player2Score;

@property (weak, nonatomic) IBOutlet UIProgressView *gameCountdownProgress;

@property (weak, nonatomic) IBOutlet UILabel *player1NameLabel;

@property (weak, nonatomic) IBOutlet UILabel *player2NameLabel;
@property (weak, nonatomic) IBOutlet UIButton *cardNWback;

@property (weak, nonatomic) IBOutlet UILabel *labelNWleft;
@property (weak, nonatomic) IBOutlet UILabel *labelNWright;
@property (weak, nonatomic) IBOutlet UILabel *labelNEleft;
@property (weak, nonatomic) IBOutlet UILabel *labelNEright;
@property (weak, nonatomic) IBOutlet UILabel *labelSWleft;
@property (weak, nonatomic) IBOutlet UILabel *labelSWright;
@property (weak, nonatomic) IBOutlet UILabel *labelSEright;
@property (weak, nonatomic) IBOutlet UILabel *labelSEleft;

@property (weak, nonatomic) IBOutlet UILabel *labelAnswer;

@end
