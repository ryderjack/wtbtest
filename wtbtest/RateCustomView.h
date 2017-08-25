//
//  RateCustomView.h
//  wtbtest
//
//  Created by Jack Ryder on 15/03/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RateCustomView;

@protocol rateDelegate <NSObject>
- (void)dismissRatePressed;
- (void)ratePressedWithNumber:(int)starNumber;
@end

@interface RateCustomView : UIView

//stars
@property (weak, nonatomic) IBOutlet UIButton *firstStar;
@property (weak, nonatomic) IBOutlet UIButton *secondStar;
@property (weak, nonatomic) IBOutlet UIButton *thirdStar;
@property (weak, nonatomic) IBOutlet UIButton *fourthStar;
@property (weak, nonatomic) IBOutlet UIButton *fifthStar;
@property (nonatomic) int starNumber;

//delegate
@property (nonatomic, weak) id <rateDelegate> delegate;

//labels
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@end
