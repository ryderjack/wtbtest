//
//  CustomCopyActivity.h
//  wtbtest
//
//  Created by Jack Ryder on 06/04/2018.
//  Copyright © 2018 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CustomCopyActivity;

@protocol CustomCopyActivityDelegate <NSObject>
- (void)copiedLinkPressed;
@end

@interface CustomCopyActivity : UIActivity

//delegate
@property (nonatomic, weak) id <CustomCopyActivityDelegate> delegate;

@end
