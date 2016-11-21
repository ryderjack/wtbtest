//
//  MakeOfferController.m
//  wtbtest
//
//  Created by Jack Ryder on 15/11/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "MakeOfferController.h"

@interface MakeOfferController ()

@end

@implementation MakeOfferController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.view.backgroundColor = [UIColor colorWithRed:0.00 green:0.00 blue:0.00 alpha:0.8];
    self.navigationController.view.backgroundColor = [UIColor colorWithRed:0.00 green:0.00 blue:0.00 alpha:0.8];
    
    self.sellingTextfield.delegate = self;
    self.conditionField.delegate = self;
    self.priceField.delegate = self;
    self.meetupField.delegate = self;
    
    self.warningLabel.text = @"";
    
    [self addDoneButton];

    UIColor *color = [UIColor lightGrayColor];
    self.sellingTextfield.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"What are you selling?" attributes:@{NSForegroundColorAttributeName: color}];
    self.conditionField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Condition" attributes:@{NSForegroundColorAttributeName: color}];
    self.priceField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Price" attributes:@{NSForegroundColorAttributeName: color}];
    self.meetupField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Meetup?" attributes:@{NSForegroundColorAttributeName: color}];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)dismissPressed:(id)sender {
    if ([self.sellingTextfield.text isEqualToString:@""] && [self.conditionField.text isEqualToString:@""] && [self.priceField.text isEqualToString:@""] && [self.meetupField.text isEqualToString:@""]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else{
        UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Cancel offer?" message:@"Are you sure you want to cancel your offer?" preferredStyle:UIAlertControllerStyleAlert];
        [alertView addAction:[UIAlertAction actionWithTitle:@"Stay" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        }]];
        [alertView addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }]];
        [self presentViewController:alertView animated:YES completion:nil];
    }
}

- (IBAction)sendOfferPressed:(id)sender {
    [self removeKeyboard];
    [self.offerButton setEnabled:NO];
    
    NSString *nameCheck = [self.sellingTextfield.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *conditionCheck = [self.conditionField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *meetupCheck = [self.meetupField.text stringByReplacingOccurrencesOfString:@" " withString:@""];

    if ([nameCheck isEqualToString:@""] ||[conditionCheck isEqualToString:@""] ||[meetupCheck isEqualToString:@""] ||[self.priceField.text isEqualToString:@""] ) {
        self.warningLabel.text = @"Fill out all the above fields";
        [self.offerButton setEnabled:YES];
    }
    else{
        NSString *offerString = [NSString stringWithFormat:@"Selling: %@\nCondition: %@\nPrice: %@\n Meetup: %@", self.sellingTextfield.text, self.conditionField.text, self.priceField.text, self.meetupField.text];
        [self dismissViewControllerAnimated:YES completion:^{
           [self.delegate sendOffer:offerString];
        }];
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField{
    self.warningLabel.text = @"";
    if (textField == self.priceField) {
        self.priceField.text = [NSString stringWithFormat:@"%@", self.currencySymbol];
    }
    else if (textField == self.meetupField){
        [self animateTextField:textField up:YES];
    }
    else if (textField == self.conditionField && [[UIScreen mainScreen ] bounds ].size.width == 320){
        [self animateTextField:textField up:YES];
    }
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    if (textField == self.priceField) {
        NSString *prefixToRemove = [NSString stringWithFormat:@"%@", self.currencySymbol];
        NSString *priceString = [[NSString alloc]init];
        priceString = [self.priceField.text substringFromIndex:[prefixToRemove length]];
        
        NSArray *priceArray = [priceString componentsSeparatedByString:@"."];
        
        NSMutableArray *priceArrayMutable = [NSMutableArray arrayWithArray:priceArray];
        
        [priceArrayMutable removeObject:@""];
        
        priceArray = priceArrayMutable;
        
        NSLog(@"price array %lu", (unsigned long)priceArray.count);
        
        if (priceArray.count == 0) {
            priceString = @"0.00";
        }
        else if (priceArray.count > 2) {
            NSLog(@"multiple decimal points added");
            priceString = @"0.00";
        }
        else if (priceArray.count == 1){
            NSString *intAmount = priceArray[0];
            NSLog(@"length of this int %@   int %lu",intAmount ,(unsigned long)intAmount.length);
            priceString = [NSString stringWithFormat:@"%@.00", intAmount];
        }
        else if (priceArray.count > 1){
            NSString *intAmount = priceArray[0];
            
            if (intAmount.length == 1){
                NSLog(@"single digit then a decimal point");
                intAmount = [NSString stringWithFormat:@"%@.00", intAmount];
            }
            else{
                //all good
                NSLog(@"length of int %lu", (unsigned long)intAmount.length);
            }
            
            NSMutableString *centAmount = priceArray[1];
            if (centAmount.length == 2){
                //all good
                NSLog(@"all good");
            }
            else if (centAmount.length == 1){
                NSLog(@"got 1 decimal place");
                centAmount = [NSMutableString stringWithFormat:@"%@0", centAmount];
            }
            else{
                NSLog(@"point but no numbers after it");
                centAmount = [NSMutableString stringWithFormat:@"00"];
            }
            
            priceString = [NSString stringWithFormat:@"%@.%@", intAmount, centAmount];
        }
        else{
            priceString = [NSString stringWithFormat:@"%@.00", priceString];
            NSLog(@"no decimal point so price is %@", priceString);
        }
        
        if ([priceString isEqualToString:[NSString stringWithFormat:@"%@0.00", self.currencySymbol]] || [priceString isEqualToString:@""] || [priceString isEqualToString:[NSString stringWithFormat:@"%@.00", self.currencySymbol]] || [priceString isEqualToString:@"  "]) {
            //invalid price number
            NSLog(@"invalid price number");
            self.warningLabel.text = @"Enter a valid price!";
            self.priceField.text = @"";
        }
        else{
            self.priceField.text = [NSString stringWithFormat:@"%@%@", self.currencySymbol, priceString];
        }
    }
    else if (textField == self.meetupField){
        [self animateTextField:textField up:NO];
    }
    else if (textField == self.conditionField && [[UIScreen mainScreen ] bounds ].size.width == 320){
        [self animateTextField:textField up:NO];
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
    self.priceField.inputAccessoryView = keyboardToolbar;
}

-(void)removeKeyboard{
    [self.conditionField resignFirstResponder];
    [self.priceField resignFirstResponder];
    [self.sellingTextfield resignFirstResponder];
    [self.meetupField resignFirstResponder];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == self.priceField) {
        // Check for deletion of the currency sign
        if (range.location == 0 && [textField.text hasPrefix:[NSString stringWithFormat:@"%@", self.currencySymbol]])
            return NO;
        
        NSString *updatedText = [textField.text stringByReplacingCharactersInRange:range withString:string];
        NSArray *stringsArray = [updatedText componentsSeparatedByString:@"."];
        
        // Check for an absurdly large amount & 0
        if (stringsArray.count > 0)
        {
            NSString *dollarAmount = stringsArray[0];
            
//            if ([dollarAmount isEqualToString:@"£0"]) {
//                return NO;
//            }
            if (dollarAmount.length > 6)
                return NO;
            // not allowed to enter all 9s
            if ([dollarAmount isEqualToString:[NSString stringWithFormat:@"%@9999", self.currencySymbol]]) {
                return NO;
            }
        }
        return YES;
    }
    
    return YES;
}

-(void)animateTextField:(UITextField*)textField up:(BOOL)up
{
    const int movementDistance = -130; // tweak as needed
    const float movementDuration = 0.3f; // tweak as needed
    
    int movement = (up ? movementDistance : -movementDistance);
    
    [UIView beginAnimations: @"animateTextField" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    [UIView commitAnimations];
}

@end
