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
    
    self.navigationItem.title = @"S H I P P I N G";
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Regular" size:13],
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
    self.countryCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.nameField.delegate = self;
    self.buildingField.delegate = self;
    self.streetField.delegate = self;
    self.cityField.delegate = self;
    self.postcodeField.delegate = self;
    self.numberField.delegate = self;
    self.countryField.delegate = self;
    
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
    if ([self.currentUser objectForKey:@"country"]) {
        self.countryField.text = [self.currentUser objectForKey:@"country"];
    }
     [self addDoneButton];
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
    return 7;
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
            return self.countryCell;
        }
        else if (indexPath.row == 6){
            return self.phoneNumCell;
        }
    }
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{

    if (indexPath.row == 6) {
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
    
    NSString *name = [self.nameField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *building = [self.buildingField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *street = [self.streetField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *number = [self.numberField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *city = [self.cityField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *postcode = [self.postcodeField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *country = [self.countryField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if ([name isEqualToString:@""] || [building isEqualToString:@""]||[street isEqualToString:@""] || [number isEqualToString:@""] || [city isEqualToString:@""] || [postcode isEqualToString:@""] || [country isEqualToString:@""]) {
        self.warningLabel.text = @"Fill out all the above fields!";
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
    }
    else{
        //pass back & save to current user
        [self.currentUser setObject:[self.buildingField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"building"];
        [self.currentUser setObject:[self.streetField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"street"];
        [self.currentUser setObject:[self.cityField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"city"];
        [self.currentUser setObject:[self.numberField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"phonenumber"];
        [self.currentUser setObject:[self.postcodeField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"postcode"];
        [self.currentUser setObject:[self.countryField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"country"];
        
        [self.currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (succeeded) {
                NSString *addressString = @"";
                
                if (self.settingsMode == YES) {
                    addressString = [NSString stringWithFormat:@"Address: %@ %@ %@ %@ %@",self.buildingField.text, self.streetField.text, self.cityField.text, self.postcodeField.text, self.numberField.text];
                }
                else{
                    addressString = [NSString stringWithFormat:@"%@\n%@ %@, %@\n%@\n%@\n%@",[self.currentUser objectForKey:@"fullname"], self.buildingField.text, self.streetField.text, self.cityField.text, self.postcodeField.text,self.countryField.text ,self.numberField.text];
                }
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

- (void)addDoneButton {
    UIToolbar* keyboardToolbar = [[UIToolbar alloc] init];
    [keyboardToolbar sizeToFit];
    UIBarButtonItem *flexBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                      target:nil action:nil];
    UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                      target:self.view action:@selector(endEditing:)];
    keyboardToolbar.items = @[flexBarButton, doneBarButton];
    self.numberField.inputAccessoryView = keyboardToolbar;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Remove seperator inset
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    // Prevent the cell from inheriting the Table View's margin settings
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    
    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}
@end
