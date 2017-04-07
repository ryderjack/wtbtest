//
//  AddImagesTutorial.m
//  wtbtest
//
//  Created by Jack Ryder on 30/01/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "AddImagesTutorial.h"
#import <Parse/Parse.h>

@interface AddImagesTutorial ()

@end

@implementation AddImagesTutorial

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.emojiLabel.adjustsFontSizeToFitWidth = YES;
    self.emojiLabel.minimumScaleFactor=0.5;
    
    // Do any additional setup after loading the view from its nib.
    self.view.backgroundColor = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:0.6];
    
    [[PFUser currentUser] setObject:@"YES" forKey:@"addImageTutorial"];
    [[PFUser currentUser]saveInBackground];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)dismissPressed:(id)sender {
    [self.delegate dismissedAddImage];
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
