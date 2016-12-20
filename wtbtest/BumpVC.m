//
//  BumpVC.m
//  wtbtest
//
//  Created by Jack Ryder on 14/12/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "BumpVC.h"

@interface BumpVC ()

@end

@implementation BumpVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.mainLabel.text = @"";
    
    [self.plusOneImageView setHidden:YES];
    
    if (self.listingID) {
        PFQuery *listingQ = [PFQuery queryWithClassName:@"wantobuys"];
        [listingQ whereKey:@"objectId" equalTo:self.listingID];
        [listingQ includeKey:@"postUser"];
        [listingQ getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if (object) {
                self.listing = object;
                
                [self.listingImageView setFile:[object objectForKey:@"image1"]];
                [self.listingImageView loadInBackground];
                
                PFUser *postUser = [self.listing objectForKey:@"postUser"];
                self.mainLabel.text = [NSString stringWithFormat:@"%@ wants to buy ‘%@’ - help them get their post noticed with a Bump!", [postUser objectForKey:@"fullname" ], [self.listing objectForKey: @"title"]];
                
            }
            else{
                NSLog(@"error finding listing");
            }
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)bumpPressed:(id)sender {
    NSMutableArray *bumpArray = [NSMutableArray arrayWithArray:[self.listing objectForKey:@"bumpArray"]];
    
    if ([bumpArray containsObject:[PFUser currentUser].objectId]) {
        NSLog(@"already bumped it");
    }
    else{
        NSLog(@"bumped");
        
        //update array
        [bumpArray addObject:[PFUser currentUser].objectId];
        [self.listing addObject:[PFUser currentUser].objectId forKey:@"bumpArray"];
        [self.listing incrementKey:@"bumpCount"];
        [self.listing saveInBackground];
    }
    
    //send push
    NSString *pushText = [NSString stringWithFormat:@"%@ just bumped your listing 👊", [[PFUser currentUser] objectForKey:@"fullname"]];
    if (![[[self.listing objectForKey:@"postUser"]objectId] isEqualToString:[[PFUser currentUser]objectId]]) {
        NSDictionary *params = @{@"userId": [[self.listing objectForKey:@"postUser"]objectId], @"message": pushText, @"sender": [PFUser currentUser].username};
        [PFCloud callFunctionInBackground:@"sendPush" withParameters:params block:^(NSDictionary *response, NSError *error) {
            if (!error) {
                NSLog(@"push response %@", response);
            }
            else{
                NSLog(@"push error %@", error);
            }
        }];
    }
    
    //animate a +1
    [self.plusOneImageView setAlpha:1.0f];
    [self.plusOneImageView setHidden:NO];

    [UIView animateWithDuration:1.0
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.plusOneImageView.transform = CGAffineTransformMakeTranslation(0, -400);
                         [self.plusOneImageView setAlpha:0.0];
                     }
                     completion:^(BOOL finished) {
                         //dismiss VC
                         [self dismissViewControllerAnimated:YES completion:nil];
                     }];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [UIView animateKeyframesWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat animations:^{
        [UIView setAnimationRepeatAutoreverses:YES]; //This ensures the animation not only animations forwards but back to its original position
        [UIView setAnimationRepeatCount:INFINITY]; //Set the number of times you want the animation to repeat
        self.bumpButton.imageView.transform = CGAffineTransformMakeTranslation(0, 20);
    } completion:^(BOOL finished) {
        
    }];
}
- (IBAction)skipPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
