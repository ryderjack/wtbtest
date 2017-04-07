//
//  AddImagesTutorial.h
//  wtbtest
//
//  Created by Jack Ryder on 30/01/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AddImagesTutorial;

@protocol AddImageDelegate <NSObject>
- (void)dismissedAddImage;

@end

@interface AddImagesTutorial : UIViewController

//delegate
@property (nonatomic, weak) id <AddImageDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *emojiLabel;

@end
