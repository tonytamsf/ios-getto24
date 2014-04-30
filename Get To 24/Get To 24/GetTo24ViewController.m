//
//  GetTo24ViewController.m
//  Get To 24
//
//  Created by Tony Tam on 1/4/14.
//  Copyright (c) 2014 Yama Llama. All rights reserved.
//
//  TODO: fix the flashing when the button changes title for the card
//

#import "GetTo24ViewController.h"
#import "PlayingCardDeck.h"
#import "Deck.h"
#import "Debug.h"

@interface GetTo24ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *flipsLabel;
@property (nonatomic) int flipCount;

- (void) startGame;

- (void) dealHand;

- (void) countdown;

@property PlayingCardDeck *_cardDeck;

@property NSArray *cards;

@property NSTimer *timer;

@property int currentGameTime;

@end

@implementation GetTo24ViewController

- (void) startGame
{
    if (! self._cardDeck) {
        self._cardDeck = [[PlayingCardDeck alloc] init];
    }
    
    self.gameCountdownProgress.progress = 0.0;
    [self dealHand];
}

- (void) countdown
{
    float percent = (60 - self.currentGameTime) / 60.0;

    DLog("Countdown %d %f", self.currentGameTime, percent);
    self.currentGameTime -= 1;
    if (self.currentGameTime <= 0) {
        [self giveUp:(id )nil];
    }
    [self.gameCountdownProgress
        setProgress:percent
            animated:YES];
}

- (void) dealHand
{
    self.currentGameTime = 60;

    [self.timer invalidate];

    for (UIButton *card in self.cards) {
        [card setTitle:[[self._cardDeck drawRandomCard] contents] forState:UIControlStateNormal];
    }

     self.timer = [NSTimer scheduledTimerWithTimeInterval:1
                               target:self
                               selector:@selector(countdown)
                               userInfo:nil
                               repeats:YES];

    [self.gameCountdownProgress setProgress:0.01 animated:YES];
    
}

- (IBAction)giveUp:(id)sender {
    [self.gameCountdownProgress setProgress:0.00 animated:YES];

    [self dealHand];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.buttonGiveUp setTransform:CGAffineTransformMakeRotation(-M_PI / 2)];
    [self.player1Button setTransform:CGAffineTransformMakeRotation(-M_PI)];
    //[self.progressBar setTransform:CGAffineTransformMakeRotation(-M_PI / 2)];
    
	// Do any additional setup after loading the view, typically from a nib.
    [self.view setMultipleTouchEnabled:YES];
    
    self.cards = [NSArray arrayWithObjects:
                  self.cardNW,
                  self.cardSW,
                  self.cardSE,
                  self.cardNE, nil];
    
    [self startGame];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) setFlipCount:(int)flipCount
{
    _flipCount = flipCount;
    [self.flipsLabel setText:[NSString stringWithFormat:@"Flips %d", self.flipCount]];
    
}


- (IBAction)touchCardButton:(UIButton *)sender
{
    if ([sender.currentTitle length]) {
        UIImage *cardImage = [UIImage imageNamed:@"cardback"];
        [sender setBackgroundImage:cardImage
                          forState:UIControlStateNormal ];
        [sender setTitle:@""
                forState:UIControlStateNormal];
    } else {
        UIImage *cardImage = [UIImage imageNamed:@"cardfront"];
        [sender setBackgroundImage:cardImage
                          forState:UIControlStateNormal ];
        [sender setTitle:@"A ♣︎"
                forState:UIControlStateNormal];
    }
    self.flipCount++;
}
@end
