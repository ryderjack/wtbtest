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
    // Do any additional setup after loading the view from its nib.
    self.view.backgroundColor = [UIColor colorWithRed:0.00 green:0.00 blue:0.00 alpha:0.7];
    
    [[PFUser currentUser] setObject:@"YES" forKey:@"addImageTutorial"];
    [[PFUser currentUser]saveInBackground];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)dismissPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
