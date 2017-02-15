//
//  notificatView.h
//  wtbtest
//
//  Created by Jack Ryder on 15/12/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ParseUI/ParseUI.h>
#import <Parse/Parse.h>

@class notificatView;
@protocol dropDelegate <NSObject>
- (void)bumpTappedForListing:(NSString *)listing;
@end


@interface notificatView : UIView
@property (weak, nonatomic) IBOutlet PFImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *mainLabel;
@property (weak, nonatomic) IBOutlet UIButton *mainButton;
@property (nonatomic, weak) id <dropDelegate> delegate;
@property (nonatomic, strong) NSString *listingID;
@property (nonatomic, strong) PFObject *listing;

//imgview
@property (nonatomic) BOOL sentMode;

@end
