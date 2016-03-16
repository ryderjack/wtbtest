//
//  ShippingController.m
//  wtbtest
//
//  Created by Jack Ryder on 09/03/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "ShippingController.h"

@interface ShippingController ()

@end

@implementation ShippingController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Shipping address";
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"AvenirNext-Regular" size:17],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    UIBarButtonItem *savebutton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(saveStuff)];
    self.navigationItem.rightBarButtonItem = savebutton;
    
    self.nameCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.buildingCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.streetnameCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.cityCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.postcodeCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.phoneNumCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.currentUser = [PFUser currentUser];
    
    self.nameField.text = [self.currentUser objectForKey:@"fullname"];
    
    if ([self.currentUser objectForKey:@"building"]) {
        self.buildingField.text = [self.currentUser objectForKey:@"building"];
    }
    if ([self.currentUser objectForKey:@"street"]) {
        self.streetField.text = [self.currentUser objectForKey:@"street"];
    }
    if ([self.currentUser objectForKey:@"city"]) {
        self.cityField.text = [self.currentUser objectForKey:@"city"];
    }
    if ([self.currentUser objectForKey:@"postcode"]) {
        self.postcodeField.text = [self.currentUser objectForKey:@"postcode"];
    }
    if ([self.currentUser objectForKey:@"phonenumber"]) {
        self.numberField.text = [self.currentUser objectForKey:@"phonenumber"];
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
    return 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section ==0){
        if (indexPath.row == 0){
            return self.nameCell;
        }
        else if (indexPath.row == 1){
            return self.buildingCell;
        }
        else if (indexPath.row == 2){
            return self.streetnameCell;
        }
        else if (indexPath.row == 3){
            return self.cityCell;
        }
        else if (indexPath.row == 4){
            return self.postcodeCell;
        }
        else if (indexPath.row == 5){
            return self.phoneNumCell;
        }
    }
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{

    if (indexPath.row == 5) {
        return 99;
    }
    return 44;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

-(void)saveStuff{
    [self.navigationItem.rightBarButtonItem setEnabled:NO];
    
    if ([self.nameField.text isEqualToString:@""] || [self.buildingField.text isEqualToString:@""]||[self.streetField.text isEqualToString:@""] || [self.numberField.text isEqualToString:@""] || [self.cityField.text isEqualToString:@""] || [self.postcodeField.text isEqualToString:@""]) {
        self.warningLabel.text = @"Fill out all the above fields!";
    }
    else{
        //pass back & save to current user
        [self.currentUser setObject:self.buildingField.text forKey:@"building"];
        [self.currentUser setObject:self.streetField.text forKey:@"street"];
        [self.currentUser setObject:self.cityField.text forKey:@"city"];
        [self.currentUser setObject:self.numberField.text forKey:@"phonenumber"];
        [self.currentUser setObject:self.postcodeField.text forKey:@"postcode"];
        [self.currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (succeeded) {
                NSString *addressString = [NSString stringWithFormat:@"%@\n%@ %@\n%@\n%@\n%@",[self.currentUser objectForKey:@"fullname"], self.buildingField.text, self.streetField.text, self.cityField.text, self.phoneNumCell.textLabel.text, self.postcodeField.text];
                [self.delegate addItemViewController:self didFinishEnteringAddress:addressString];
                [self.navigationController popViewControllerAnimated:YES];
            }
            else{
                [self.navigationItem.rightBarButtonItem setEnabled:YES];
                NSLog(@"error %@", error);
            }
        }];
        
    }
}
@end