//
//  MakeOfferController.h
//  wtbtest
//
//  Created by Jack Ryder on 15/11/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
@class MakeOfferController;

@protocol MakeOfferDelegate <NSObject>
- (void)sendOffer:(NSString *)offerString;
@end

@interface MakeOfferController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *sellingTextfield;
@property (weak, nonatomic) IBOutlet UITextField *priceField;
@property (weak, nonatomic) IBOutlet UITextField *conditionField;
@property (weak, nonatomic) IBOutlet UITextField *meetupField;
@property (nonatomic, weak) id <MakeOfferDelegate> delegate;
@property (nonatomic, strong) NSString *currencySymbol;
@property (weak, nonatomic) IBOutlet UILabel *warningLabel;
@property (weak, nonatomic) IBOutlet UIButton *offerButton;

@end
