//
//  bumperCell.h
//  wtbtest
//
//  Created by Jack Ryder on 17/01/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ParseUI/ParseUI.h>

@interface bumperCell : UITableViewCell
@property (weak, nonatomic) IBOutlet PFImageView *userImageView;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;

@end
