//
//  BoostViewController.m
//  wtbtest
//
//  Created by Jack Ryder on 15/01/2018.
//  Copyright © 2018 Jack Ryder. All rights reserved.
//

#import "BoostViewController.h"

@implementation BoostViewController


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
//    self.rightButton.titleLabel.adjustsFontSizeToFitWidth = YES;
//    self.rightButton.titleLabel.minimumScaleFactor=0.5;
    
    self.leftButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.leftButton.titleLabel.minimumScaleFactor=0.5;
    
    // Drawing code
    [self.introLowerLabel setHidden:YES];
    [self.bolttImageView setHidden:YES];
    [self.payExplainLabel setHidden:YES];
    
    [self.leftButton setHidden:YES];
    [self.rightButton setHidden:YES];
    
    [self.mainButton setHidden:NO];
    [self.introLowerLabel setHidden:NO];

    if ([self.mode isEqualToString:@"countdown"]) {
        //explain how pay works
        self.topLabel.text = @"BOOST\n\n10x more likely to sell your item";
        
        //display correct current symbol
        if (self.priceString) {
            
            NSLog(@"price string: %@", self.priceString);
            
            if ([self.priceString isEqualToString:@"FREE"]) {
                self.payExplainLabel.text = [self.payExplainLabel.text stringByReplacingOccurrencesOfString:@"Pay $1" withString:@"Use your Free credit"];
            }
            else{
                self.payExplainLabel.text = [self.payExplainLabel.text stringByReplacingOccurrencesOfString:@"$1" withString:self.priceString];
            }
            
            [self.rightButton setTitle:[self.rightButton.titleLabel.text stringByReplacingOccurrencesOfString:@"$0.99" withString:self.priceString] forState:UIControlStateNormal];
        }
        
        if (self.waitHoursString) {
            [self.leftButton setTitle:[self.leftButton.titleLabel.text stringByReplacingOccurrencesOfString:@"24 hours" withString:self.waitHoursString] forState:UIControlStateNormal];
        }
        else{
            [self.leftButton setTitle:@"Wait" forState:UIControlStateNormal];
        }
        
        [self.leftButton setHidden:NO];
        [self.rightButton setHidden:NO];
        [self.payExplainLabel setHidden:NO];

        [self.introLowerLabel setHidden:YES];
        [self.lowerWaitLabel setHidden:YES];
        [self.mainButton setHidden:YES];
        
    }
    else if([self.mode isEqualToString:@"success"]){
        self.topLabel.text = @"Congrats, your BOOST was successful!";
        
        [self.lowerWaitLabel setHidden:NO];
        [self.bolttImageView setHidden:NO];
        
        [self.mainButton setTitle:@"D I S M I S S" forState:UIControlStateNormal];
        [self.mainButton setBackgroundColor:[UIColor colorWithRed:0.96 green:0.97 blue:0.99 alpha:1.0]];
        [self.mainButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        
        [self.introLowerLabel setHidden:YES];

    }
    else if([self.mode isEqualToString:@"boost"]){
        self.topLabel.text = @"Increase your chances of selling and boost your listing to the top of the Home Feed";
        
        [self.mainButton setTitle:@"F R E E  B O O S T" forState:UIControlStateNormal];
        [self.mainButton setBackgroundColor:[UIColor blackColor]];
        [self.mainButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        if (self.priceString) {
            
            NSString *newString = [self.introLowerLabel.text stringByReplacingOccurrencesOfString:@"$1" withString:self.priceString];
            
            NSMutableAttributedString *labelAttributedText = [[NSMutableAttributedString alloc]initWithString:newString attributes:@{NSForegroundColorAttributeName:[UIColor blackColor],NSFontAttributeName: [UIFont fontWithName:@"PingFangSC-Regular" size:13]}];
            
            [self modifyString:labelAttributedText setFontForText:@"10x more"];
            [self modifyString:labelAttributedText setFontForText:@"every 24 hours"];
            [self modifyString:labelAttributedText setFontForText:@"any time"];

            self.introLowerLabel.attributedText = labelAttributedText;
        }
        
        [self.introLowerLabel setHidden:NO];
        [self.lowerWaitLabel setHidden:YES];
    }
}

-(NSMutableAttributedString *)modifyString: (NSMutableAttributedString *)mainString setFontForText:(NSString*) textToFind
{
    NSRange range = [mainString.mutableString rangeOfString:textToFind options:NSCaseInsensitiveSearch];
    
    if (range.location != NSNotFound) {
        [mainString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"PingFangSC-Semibold" size:13] range:range];
    }
    
    return mainString;
}

- (IBAction)mainButtonPressed:(id)sender {
    
    if ([self.mode isEqualToString:@"boost"]) {
        [self.delegate FreeBoostPressed];
    }
    else{
        //success mode
        [self.delegate DismissBOOSTPressed];
    }
}

- (IBAction)leftButtonPressed:(id)sender {
    [self.delegate WaitBOOSTPressed];
}
- (IBAction)rightButtonPressed:(id)sender {
    [self.delegate PaidBOOSTPressed];
}

@end
