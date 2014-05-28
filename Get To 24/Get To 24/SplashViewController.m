//
//  SplashViewController.m
//  Get To 24
//
//  Created by Tony Tam on 5/27/14.
//  Copyright (c) 2014 Yama Llama. All rights reserved.
//

#import "SplashViewController.h"
#import "Debug.h"
#import <AVFoundation/AVFoundation.h>
#import "PBJVideoPlayerController.h"
#import "GetTo24ViewController.h"

@interface SplashViewController () < PBJVideoPlayerControllerDelegate >
@end

@implementation SplashViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    DLog(@"SplashViewController.h");
    
    PBJVideoPlayerController *_videoPlayerController = [[PBJVideoPlayerController alloc] init];
    _videoPlayerController.delegate = self;
    _videoPlayerController.view.frame = self.view.bounds;
    
    NSString *path  = [[NSBundle mainBundle] pathForResource:@"24-video" ofType :@"mov"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        DLog(@"playing %@", fName);
        
        NSURL *pathURL = [NSURL fileURLWithPath:path];
        
        _videoPlayerController.videoPath = [pathURL absoluteString];
    }
    // present
    [self addChildViewController:_videoPlayerController];
    [self.view addSubview:_videoPlayerController.view];
    [_videoPlayerController didMoveToParentViewController:self];
    [_videoPlayerController playFromBeginning];
    [_videoPlayerController setPlaybackLoops:FALSE];
    [_videoPlayerController.view setUserInteractionEnabled:FALSE];
    
    self._videoPlayerController = _videoPlayerController;
}

- (void)videoPlayerPlaybackStateDidChange:(PBJVideoPlayerController *)videoPlayer
{
}

- (void)videoPlayerReady:(PBJVideoPlayerController *)videoPlayer
{
    //NSLog(@"Max duration of the video: %f", videoPlayer.maxDuration);
}


- (void)videoPlayerPlaybackWillStartFromBeginning:(PBJVideoPlayerController *)videoPlayer
{

}


- (void)videoPlayerPlaybackDidEnd:(PBJVideoPlayerController *)videoPlayer
{
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];

    GetTo24ViewController *playView = [storyBoard instantiateViewControllerWithIdentifier:@"playView"];
    [self addChildViewController: playView];
    [self.view addSubview:playView.view];
    self._videoPlayerController.view.hidden = TRUE;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
