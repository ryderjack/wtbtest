//
//  SearchCell.h
//  wtbtest
//
//  Created by Jack Ryder on 15/02/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ParseUI/ParseUI.h>

@interface SearchCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet PFImageView *userImageView;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@end
