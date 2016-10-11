//
//  MessageTutorial.m
//  wtbtest
//
//  Created by Jack Ryder on 05/10/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "MessageTutorial.h"
#import <Parse/Parse.h>

@interface MessageTutorial ()

@end

@implementation MessageTutorial

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    PFUser *current = [PFUser currentUser];
    
    if (![[current objectForKey:@"completedMsgIntro"]isEqualToString:@"YES"]) {
        [current setObject:@"YES" forKey:@"completedMsgIntro"];
        [current saveInBackground];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)dismissPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
