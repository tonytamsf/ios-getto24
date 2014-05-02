//
//  GetTo24ViewController.m
//  Get To 24
//
//  Created by Tony Tam on 1/4/14.
//  Copyright (c) 2014 Yama Llama. All rights reserved.
//
//  TODO: fix the flashing when the button changes title for the card
//  TODO: visual should be red, black
//  TODO: should be readable upside down

#import "GetTo24ViewController.h"
#import "PlayingCardDeck.h"
#import "Deck.h"
#import "Debug.h"
#import "NSArrayUtil.h"

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

@property int player1ScorePoints;

@property int player2ScorePoints;

@property NSMutableArray *hand;


@end

@implementation GetTo24ViewController

- (IBAction)skip:(id)sender {
    [self dealHand];
}

- (void) startGame
{
    if (! self._cardDeck) {
        self._cardDeck = [[PlayingCardDeck alloc] init];
    }
    
    self.hand = [[NSMutableArray alloc] init];
    self.gameCountdownProgress.progress = 0.0;
    [self dealHand];
}

- (void) countdown
{
    float percent = (60 - self.currentGameTime) / 60.0;

    //DLog("Countdown %d %f", self.currentGameTime, percent);
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

    // TODO what if we run out of cards, time to call a winner
    self.currentGameTime = 60;

    [self.timer invalidate];


    [self.hand removeAllObjects];
    for (UIButton *card in self.cards) {
        PlayingCard *newCard = (PlayingCard *)[self._cardDeck drawRandomCard];
        
        
        [self.hand addObject:newCard];

        [card setTitle:[newCard contents] forState:UIControlStateNormal];
        [card setTitleColor:[newCard cardColor] forState:UIControlStateNormal];
    }
    NSLog(@"--------------------- %@", self.hand);

    [self calcuateAnswer];

     self.timer = [NSTimer scheduledTimerWithTimeInterval:1
                               target:self
                               selector:@selector(countdown)
                               userInfo:nil
                               repeats:YES];

    [self.gameCountdownProgress setProgress:0.01 animated:YES];
    
}

- (IBAction)giveUp:(id)sender {
    [self.gameCountdownProgress setProgress:0.00 animated:NO];

    [self dealHand];
}

- (IBAction)player1Pressed:(id)sender {
    self.player1ScorePoints += 1;
    self.player1Score.text = [NSString stringWithFormat:@"%d",
                                                        self.player1ScorePoints];
    [self dealHand];

}

- (IBAction)player2Pressed:(id)sender {
    self.player2ScorePoints += 1;
    self.player2Score.text = [NSString stringWithFormat:@"%d",
                              self.player2ScorePoints];
    [self dealHand];

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.buttonGiveUp setTransform:CGAffineTransformMakeRotation(-M_PI / 2)];
    [self.player1Button setTransform:CGAffineTransformMakeRotation(-M_PI)];
    [self.player1Score setTransform:CGAffineTransformMakeRotation(-M_PI)];
    [self.player1NameLabel setTransform:CGAffineTransformMakeRotation(-M_PI)];


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

//
// Take current hand and calcuate the answer
//
- (void) calcuateAnswer
{
    NSMutableArray *tryHand = [(NSArray *)self.hand allPermutations];

    for (int i = 0; i < [tryHand count] - 1; ++i) {
        NSLog(@"**************** %@", tryHand[i]);
    }
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
