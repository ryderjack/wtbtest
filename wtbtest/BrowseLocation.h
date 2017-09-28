//
//  BrowseLocation.h
//  wtbtest
//
//  Created by Jack Ryder on 19/09/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BrowseLocation;

@protocol BrowseLocationDelegate <NSObject>
- (void)locationPressed:(NSString *)loc;
@end


@interface BrowseLocation : UIView
@property (weak, nonatomic) IBOutlet UIButton *aroundMeButton;
@property (weak, nonatomic) IBOutlet UIButton *AsiaButton;
@property (weak, nonatomic) IBOutlet UIButton *EuropeButton;
@property (weak, nonatomic) IBOutlet UIButton *GlobalButton;
@property (weak, nonatomic) IBOutlet UIButton *AmericaButton;

//delegate
@property (nonatomic, weak) id <BrowseLocationDelegate> delegate;

@end
