//
//  SendDialogBox.m
//  wtbtest
//
//  Created by Jack Ryder on 07/02/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "SendDialogBox.h"
#import "SendToUserCell.h"
#import <FBSDKShareKit/FBSDKShareKit.h>

@implementation SendDialogBox


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    
    [self.noFriendsButton setHidden:YES];
    [self.smallInviteButton setHidden:YES];
    
    self.noFriendsButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.noFriendsButton.titleLabel.textAlignment = NSTextAlignmentCenter; // if you want to
    [self.noFriendsButton setTitle: @"I N V I T E  F A C E B O O K  F R I E N D S" forState: UIControlStateNormal];
    
    self.backgroundColor = [UIColor whiteColor];
    
    self.usernameLabel.adjustsFontSizeToFitWidth = YES;
    self.usernameLabel.minimumScaleFactor=0.5;
    
    self.usernameLabel.text = @"";

    //setup collectionView
    [self.collectionView registerClass:[SendToUserCell class] forCellWithReuseIdentifier:@"Cell"];
    
    UINib *cellNib = [UINib nibWithNibName:@"SendToUserCell" bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"Cell"];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
    layout.itemSize = CGSizeMake(104, 104);
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    [self.collectionView setCollectionViewLayout:layout];
    self.collectionView.showsHorizontalScrollIndicator = NO;
}

//collection view

- (void)setCollectionViewDataSourceDelegate:(id<UICollectionViewDataSource, UICollectionViewDelegate>)dataSourceDelegate indexPath:(NSIndexPath *)indexPath
{
    self.collectionView.dataSource = dataSourceDelegate;
    self.collectionView.delegate = dataSourceDelegate;
    [self.collectionView reloadData];
}



@end
