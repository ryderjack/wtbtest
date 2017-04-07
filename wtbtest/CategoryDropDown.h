//
//  CategoryDropDown.h
//  wtbtest
//
//  Created by Jack Ryder on 03/04/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CategoryDropDown;
@protocol categoryDelegate <NSObject>
- (void)clothingPressed;
- (void)footPressed;
- (void)otherPressed;

@end

@interface CategoryDropDown : UIView

//delegate
@property (nonatomic, weak) id <categoryDelegate> delegate;

@end
