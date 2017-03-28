//
//  ReviewsVC.m
//  wtbtest
//
//  Created by Jack Ryder on 09/11/2016.
//  Copyright © 2016 Jack Ryder. All rights reserved.
//

#import "ReviewsVC.h"
#import "ReviewCell.h"

@interface ReviewsVC ()

@end

@implementation ReviewsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"R E V I E W S";
    
    self.tableView.backgroundColor = [UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1];
    [self.tableView registerNib:[UINib nibWithNibName:@"ReviewCell" bundle:nil] forCellReuseIdentifier:@"Cell"];
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setLocale:[NSLocale currentLocale]];
    [self.dateFormatter setDateFormat:@"dd MMM"];
    
    self.feedbackArray = [NSMutableArray array];
    
    [self loadFeedback];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)loadFeedback{
    //first query for sales feedback
    PFQuery *salesQuery = [PFQuery queryWithClassName:@"feedback"];
    [salesQuery whereKey:@"sellerUser" equalTo:self.user];
    [salesQuery whereKey:@"gaveFeedback" notEqualTo:self.user];
    [salesQuery includeKey:@"buyerUser"];
    [salesQuery includeKey:@"gaveFeedback"];
    [salesQuery orderByDescending:@"createdAt"];
    [salesQuery includeKey:@"WTB"];
    [salesQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (!error) {
            [self.feedbackArray removeAllObjects];
            [self.feedbackArray addObjectsFromArray:objects];
            
            //query for purchase feedback
            PFQuery *purchaseQuery = [PFQuery queryWithClassName:@"feedback"];
            [purchaseQuery whereKey:@"buyerUser" equalTo:self.user];
            [purchaseQuery whereKey:@"gaveFeedback" notEqualTo:self.user];
            [purchaseQuery includeKey:@"gaveFeedback"];
            [purchaseQuery includeKey:@"sellerUser"];
            [purchaseQuery includeKey:@"WTB"];
            [purchaseQuery orderByDescending:@"createdAt"];
            [purchaseQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                if (!error) {
                    [self.feedbackArray addObjectsFromArray:objects];
                    NSSortDescriptor *sortDescriptor;
                    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt"
                                                                 ascending:NO];
                    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
                    NSArray *sortedArray = [self.feedbackArray sortedArrayUsingDescriptors:sortDescriptors];
                    
                    [self.feedbackArray removeAllObjects];
                    [self.feedbackArray addObjectsFromArray:sortedArray];
                    
                    NSLog(@"feedback %@", self.feedbackArray);
                    
                    if (self.feedbackArray.count == 0) {
                        //show label
                    }
                    
                    [self.tableView reloadData];
                }
                else{
                    NSLog(@"error %@", error);
                }
            }];
        }
        else{
            NSLog(@"error %@", error);
        }
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.feedbackArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ReviewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    if (!cell) {
        cell = [[ReviewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    [cell.itemImageView setHidden:YES];
    cell.userImageView.image = nil;
    cell.itemImageView.image = nil;
    
    [self setImageBorder:cell.userImageView withNumber:30];
    
    PFObject *feedbackObject = [self.feedbackArray objectAtIndex:indexPath.row];
    
    //set time
    NSDate *formattedDate = feedbackObject.createdAt;
    cell.timeLabel.text = [NSString stringWithFormat:@"%@",[self.dateFormatter stringFromDate:formattedDate]];
    
    int starNumber = [[feedbackObject objectForKey:@"rating"]intValue];
    
    if (starNumber == 0) {
        [cell.starImageView setImage:[UIImage imageNamed:@"0star"]];
    }
    else if (starNumber == 1){
        [cell.starImageView setImage:[UIImage imageNamed:@"1star"]];
    }
    else if (starNumber == 2){
        [cell.starImageView setImage:[UIImage imageNamed:@"2star"]];
    }
    else if (starNumber == 3){
        [cell.starImageView setImage:[UIImage imageNamed:@"3star"]];
    }
    else if (starNumber == 4){
        [cell.starImageView setImage:[UIImage imageNamed:@"4star"]];
    }
    else if (starNumber == 5){
        [cell.starImageView setImage:[UIImage imageNamed:@"5star"]];
    }

    PFUser *gaveUser = [feedbackObject objectForKey:@"gaveFeedback"];
    [cell.userImageView setFile:[gaveUser objectForKey:@"picture"]];
    [cell.userImageView loadInBackground];
    cell.usernameLabel.text = gaveUser.username;
    
    cell.commentLabel.text = [feedbackObject objectForKey:@"comment"];

    return cell;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:NO];
    
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Regular" size:13],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
}

-(void)setImageBorder:(UIImageView *)imageView withNumber:(int)number{
    imageView.layer.cornerRadius =  number;
    imageView.layer.masksToBounds = YES;
    imageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    imageView.contentMode = UIViewContentModeScaleAspectFill;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 141;
}

@end
