//
//  SettingsController.m
//  wtbtest
//
//  Created by Jack Ryder on 27/06/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "SettingsController.h"


@interface SettingsController ()

@end

@implementation SettingsController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"AvenirNext-Regular" size:17],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    self.navigationItem.title = @"Settings";
    
    self.currentUser = [PFUser currentUser];
    
    self.nameLabel.text = [NSString stringWithFormat:@"Name: %@",[self.currentUser objectForKey:@"fullname"]];
    self.emailFields.placeholder = [NSString stringWithFormat:@"Email: %@",[self.currentUser objectForKey:@"email"]];
    
    if ([self.currentUser objectForKey:@"building"]) {
        //address been set before
        self.addLabel.text = [NSString stringWithFormat:@"%@ %@ %@ %@ %@",[self.currentUser objectForKey:@"building"], [self.currentUser objectForKey:@"street"], [self.currentUser objectForKey:@"city"], [self.currentUser objectForKey:@"postcode"], [self.currentUser objectForKey:@"phonenumber"]];
    }
    else{
        self.addLabel.text = @"Address";
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 3;
    }
    else if (section == 1){
        return 1;
    }
    else{
       return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            return self.nameCell;
        }
        else if (indexPath.row == 1) {
            return self.emailCell;
        }
        else if (indexPath.row == 2) {
            return self.addressCell;
        }
    }
    return nil;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) {
        if (indexPath.row == 2) {
            //goto shipping controller
            ShippingController *vc = [[ShippingController alloc]init];
            vc.delegate = self;
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
}

-(void)addItemViewController:(ShippingController *)controller didFinishEnteringAddress:(NSString *)address{
    self.addLabel.text = address;
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    if (textField == self.emailFields) {
        [self.currentUser setObject:self.emailFields.text forKey:@"email"];
        [self.currentUser saveInBackground];
    }
}
@end
