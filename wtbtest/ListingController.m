//
//  ListingController.m
//  
//
//  Created by Jack Ryder on 03/03/2016.
//
//

#import "ListingController.h"
#import "DetailImageController.h"
#import "ExplainViewController.h"
#import "MakeOfferViewController.h"

@interface ListingController ()

@end

@implementation ListingController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Listing";
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"AvenirNext-Regular" size:17],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    UIBarButtonItem *infoButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"question"] style:UIBarButtonItemStylePlain target:self action:@selector(showExtraInfo)];
    
    self.navigationItem.rightBarButtonItem = infoButton;
    
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    
    // Setting the swipe direction.
    [swipeLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
    [swipeRight setDirection:UISwipeGestureRecognizerDirectionRight];
    
    // Adding the swipe gesture on image view
    [self.picView addGestureRecognizer:swipeLeft];
    [self.picView addGestureRecognizer:swipeRight];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(presentDetailImage)];
    tap.numberOfTapsRequired = 1;
    [self.picView addGestureRecognizer:tap];

    [self.picView setUserInteractionEnabled:YES];
    
    //hide first table view header
    self.tableView.contentInset = UIEdgeInsetsMake(-1.0f, 0.0f, 0.0f, 0.0);
    
    self.buyernameLabel.adjustsFontSizeToFitWidth = YES;
    self.buyernameLabel.minimumScaleFactor=0.5;
    
    self.locationLabel.adjustsFontSizeToFitWidth = YES;
    self.locationLabel.minimumScaleFactor=0.5;
    
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.titleLabel.minimumScaleFactor=0.5;
    
    if ([self.listingObject objectForKey:@"image2"]) {
        [self.picIndicator setNumberOfPages:2];
        self.numberOfPics = 2;
        self.firstImage = [self.listingObject objectForKey:@"image1"];
        self.secondImage = [self.listingObject objectForKey:@"image2"];
    }
    else if ([self.listingObject objectForKey:@"image3"]){
        [self.picIndicator setNumberOfPages:3];
        self.numberOfPics = 3;
        self.firstImage = [self.listingObject objectForKey:@"image1"];
        self.secondImage = [self.listingObject objectForKey:@"image2"];
        self.thirdImage = [self.listingObject objectForKey:@"image3"];
    }
    else if ([self.listingObject objectForKey:@"image4"]){
        [self.picIndicator setNumberOfPages:4];
        self.numberOfPics = 4;
        self.firstImage = [self.listingObject objectForKey:@"image1"];
        self.secondImage = [self.listingObject objectForKey:@"image2"];
        self.thirdImage = [self.listingObject objectForKey:@"image3"];
        self.fourthImage = [self.listingObject objectForKey:@"image4"];
    }
    else{
        [self.picIndicator setHidden:YES];
        self.numberOfPics = 1;
    }
    
    self.picView.contentMode = UIViewContentModeScaleAspectFit;
    [self.picView setFile:[self.listingObject objectForKey:@"image1"]];
    [self.picView loadInBackground];
    
    self.mainCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.payCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.sizeCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.deliveryCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.locationCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.extraCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.adminCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.buyerinfoCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.buttonCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.conditionCell.selectionStyle = UITableViewCellSelectionStyleNone;

    self.titleLabel.text = [self.listingObject objectForKey:@"title"];
    self.priceLabel.text = [NSString stringWithFormat:@"£%@",[self.listingObject objectForKey:@"price"]];
    self.conditionLabel.text = [self.listingObject objectForKey:@"condition"];
    self.locationLabel.text = [self.listingObject objectForKey:@"location"];
    self.deliveryLabel.text = [self.listingObject objectForKey:@"delivery"];
    
    if (![self.listingObject objectForKey:@"sizegender"]) {
        self.sizeLabel.text = [NSString stringWithFormat:@"%@", [self.listingObject objectForKey:@"size"]];
    }
    else{
        self.sizeLabel.text = [NSString stringWithFormat:@"%@, UK %@",[self.listingObject objectForKey:@"sizegender"], [self.listingObject objectForKey:@"size"]];
    }
    
    if (![self.listingObject objectForKey:@"extra"]) {
        self.extraCellNeeded = NO;
        self.extraLabel.text = @"";
    }
    else{
        self.extraCellNeeded = YES;
        self.extraLabel.text = [self.listingObject objectForKey:@"extra"];
    }
    
    [self calcPostedDate];
    
    self.idLabel.text = [NSString stringWithFormat:@"ID: %@",self.listingObject.objectId];
    
    //buyer info
    PFUser *buyer = [self.listingObject objectForKey:@"postUser"];
    
    [self setImageBorder];
    
    [buyer fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            PFFile *pic = [buyer objectForKey:@"picture"];
            [self.buyerImgView setFile:pic];
            [self.buyerImgView loadInBackground];
            self.buyernameLabel.text = buyer.username;
        }
        else{
            NSLog(@"error %@", error);
        }
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

//hide the first header in table view
- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return 1.0f;
    else if(section == 2){
        return 32.0f;
    }
    return 0.0f;
}

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
    return @"";
    
}
-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
   
    if (section == 1 || section == 3)
        return 0.0f;
    
    return 32.0f;
}


-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Remove seperator inset
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    // Prevent the cell from inheriting the Table View's margin settings
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    
    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0){
        return 1;
    }
    else if (section ==1){
        if (self.extraCellNeeded == YES) {
            return 7;
        }
        else{
            return 6;
        }
    }
    else if (section ==2){
        return 1;
    }
    else if (section ==3){
        return 1;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return self.mainCell;
        }
    }
    else if (indexPath.section == 1){
        if (indexPath.row == 0) {
            return self.payCell;
        }
        else if (indexPath.row == 1){
            return self.sizeCell;
        }
        else if (indexPath.row == 2){
            return self.conditionCell;
        }
        else if (indexPath.row == 3){
            return self.locationCell;
        }
        else if (indexPath.row == 4){
            return self.deliveryCell;
        }
        else if (indexPath.row == 5){
            if (self.extraCellNeeded == YES) {
                return self.extraCell;
            }
            else{
                return self.adminCell;
            }
        }
        else if (indexPath.row == 6){
            if (self.extraCellNeeded == YES) {
                return self.adminCell;
            }
            else{
                return nil;
            }
        }
    }
    else if (indexPath.section == 2){
        if (indexPath.row == 0) {
            return self.buttonCell;
        }
    }
    else if (indexPath.section ==3){
        if (indexPath.row == 0){
            return self.buyerinfoCell;
        }
    }
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return 314;
        }
    }
    else if (indexPath.section == 1){
        if (indexPath.row == 0) {
            return 44;
        }
        else if (indexPath.row == 1){
            return 44;
        }
        else if (indexPath.row == 2){
            return 44;
        }
        else if (indexPath.row == 3){
            return 44;
        }
        else if (indexPath.row == 4){
            return 44;
        }
        else if (indexPath.row == 5){
            if (self.extraCellNeeded == YES) {
                return 104;
            }
            else{
                return 44;
            }
        }
        else if (indexPath.row == 6){
            if (self.extraCellNeeded == YES) {
                return 44;;
            }
            else{
            }
        }
    }
    else if (indexPath.section == 2){
        if (indexPath.row == 0) {
            return 207;
        }
    }
    else if (indexPath.section ==3){
        if (indexPath.row == 0){
            return 158;
        }
    }
    return 44;

}

-(void) calcPostedDate{
    NSDate *createdDate = self.listingObject.createdAt;
    NSDate *now = [NSDate date];
    
    NSTimeInterval distanceBetweenDates = [now timeIntervalSinceDate:createdDate];
    double secondsInAnHour = 3600;
    float minsBetweenDates = (distanceBetweenDates / secondsInAnHour)*60;
    if (minsBetweenDates > 0 && minsBetweenDates < 1) {
        //seconds
        self.postedLabel.text = [NSString stringWithFormat:@"Posted: %.fs ago", (minsBetweenDates*60)];
    }
    else if (minsBetweenDates == 1){
        //1 min
        self.postedLabel.text = @"Posted: 1m ago";
    }
    else if (minsBetweenDates > 1 && minsBetweenDates <60){
        //mins
        self.postedLabel.text = [NSString stringWithFormat:@"Posted: %.fm ago", minsBetweenDates];
    }
    else if (minsBetweenDates == 60){
        //1 hour
        self.postedLabel.text = @"Posted: 1h ago";
    }
    else if (minsBetweenDates > 60 && minsBetweenDates <1440){
        //hours
        self.postedLabel.text = [NSString stringWithFormat:@"Posted: %.fh ago", (minsBetweenDates/60)];
    }
    else if (minsBetweenDates > 1440 && minsBetweenDates < 2880){
        //1 day
        self.postedLabel.text = [NSString stringWithFormat:@"Posted: %.fd ago", (minsBetweenDates/1440)];
    }
    else if (minsBetweenDates > 2880 && minsBetweenDates < 10080){
        //days
        self.postedLabel.text = [NSString stringWithFormat:@"Posted: %.fd ago", (minsBetweenDates/1440)];
    }
    else if (minsBetweenDates > 10080){
        //weeks
        self.postedLabel.text = [NSString stringWithFormat:@"Posted: %.fw ago", (minsBetweenDates/10080)];
    }
    else{
    }
}
- (IBAction)saveForLaterPressed:(id)sender {
}
- (IBAction)sharePressed:(id)sender {
    NSMutableArray *items = [NSMutableArray new];
    [items addObject:[NSString stringWithFormat:@"Check out this WTB: %@ for %@", [self.listingObject objectForKey:@"title"], [self.listingObject objectForKey:@"price"]]];
    UIActivityViewController *activityController = [[UIActivityViewController alloc]initWithActivityItems:items applicationActivities:nil];
    [self presentViewController:activityController animated:YES completion:nil];
}
- (IBAction)wantobuytooPressed:(id)sender {
}

-(void)setImageBorder{
    self.buyerImgView.layer.cornerRadius = self.buyerImgView.frame.size.width / 2;
    self.buyerImgView.layer.masksToBounds = YES;
    
    self.buyerImgView.layer.borderWidth = 1.0f;
    self.buyerImgView.layer.borderColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1].CGColor;
    
    self.buyerImgView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    self.buyerImgView.contentMode = UIViewContentModeScaleAspectFill;
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)swipe {
    
    if (swipe.direction == UISwipeGestureRecognizerDirectionLeft) {
        NSLog(@"Left Swipe");
        if (self.picIndicator.currentPage != 4) {
            if (self.picIndicator.currentPage == 0) {
                [self.picView setFile:self.secondImage];
                [self.picIndicator setCurrentPage:1];
            }
            else if (self.picIndicator.currentPage == 1){
                [self.picView setFile:self.thirdImage];
                [self.picIndicator setCurrentPage:2];
            }
            else if (self.picIndicator.currentPage == 2){
                [self.picView setFile:self.fourthImage];
                [self.picIndicator setCurrentPage:3];
            }
            [self.picView loadInBackground];
        }
    }
    if (swipe.direction == UISwipeGestureRecognizerDirectionRight) {
        NSLog(@"Right Swipe");
        if (self.picIndicator.currentPage != 0) {
            if (self.picIndicator.currentPage == 1) {
                [UIView animateWithDuration:0.5f animations:^{
                    [self.picView setFile:self.firstImage];
                }];
                [self.picIndicator setCurrentPage:0];
            }
            else if (self.picIndicator.currentPage == 2){
                [self.picView setFile:self.secondImage];
                [self.picIndicator setCurrentPage:1];
            }
            else if (self.picIndicator.currentPage == 3){
                [self.picView setFile:self.thirdImage];
                [self.picIndicator setCurrentPage:2];
            }
            [self.picView loadInBackground];
        }
    }
}

-(void)presentDetailImage{
    DetailImageController *vc = [[DetailImageController alloc]init];
    if (self.numberOfPics == 1) {
        vc.numberOfPics = 1;
        vc.listing = self.listingObject;
    }
    else if (self.numberOfPics == 2){
        vc.numberOfPics = 2;
        vc.firstImage = self.firstImage;
        vc.listing = self.listingObject;
    }
    else if (self.numberOfPics == 3){
        vc.numberOfPics = 3;
        vc.listing = self.listingObject;
    }
    else if (self.numberOfPics == 4){
        vc.numberOfPics = 4;
        vc.listing = self.listingObject;
    }
    [self presentViewController:vc animated:YES completion:nil];
}

-(void)showExtraInfo{
    ExplainViewController *vc = [[ExplainViewController alloc]init];
    vc.setting = @"process";
    [self presentViewController:vc animated:YES completion:nil];
}
- (IBAction)sellthisPressed:(id)sender {
    MakeOfferViewController *vc = [[MakeOfferViewController alloc]init];
    vc.listingObject = self.listingObject;
    [self.navigationController pushViewController:vc animated:YES];
}
@end
