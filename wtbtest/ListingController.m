//
//  ListingController.m
//  
//
//  Created by Jack Ryder on 03/03/2016.
//
//

#import "ListingController.h"
#import "CreateViewController.h"
#import "FeedbackController.h"
#import "MessageViewController.h"
#import "FBGroupShareViewController.h"
#import "UserProfileController.h"
#import <Crashlytics/Crashlytics.h>
#import "NavigationController.h"
#import "whoBumpedTableView.h"

@interface ListingController ()

@end

@implementation ListingController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"L I S T I N G";
    
    UIBarButtonItem *infoButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"dotsIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(showAlertView)];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    
    [self.checkImageView setHidden:YES];
    [self.purchasedLabel setHidden:YES];
    [self.purchasedCheckView setHidden:YES];
    
    self.currency = [[PFUser currentUser]objectForKey:@"currency"];
    if ([self.currency isEqualToString:@"GBP"]) {
        self.currencySymbol = @"£";
    }
    else if ([self.currency isEqualToString:@"EUR"]) {
        self.currencySymbol = @"€";
    }
    else if ([self.currency isEqualToString:@"USD"]) {
        self.currencySymbol = @"$";
    }
    
    self.buyernameLabel.text = @"";
    self.pastDealsLabel.text = @"Loading";
    
    //how to work out cells to display
    //create array of cells and add to it when want to display
    
    self.cellArray = [NSMutableArray array];
    
    self.longButton = [[UIButton alloc]initWithFrame:CGRectMake(0, [UIApplication sharedApplication].keyWindow.frame.size.height-(60 + self.tabBarController.tabBar.frame.size.height), [UIApplication sharedApplication].keyWindow.frame.size.width, 60)];
    [self.longButton.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:13]];
    [self.longButton setBackgroundColor:[UIColor colorWithRed:0.24 green:0.59 blue:1.00 alpha:1.0]];
    [self.longButton addTarget:self action:@selector(BarButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    self.longButton.alpha = 0.0f;
    [[UIApplication sharedApplication].keyWindow addSubview:self.longButton];
    [self showBarButton];
    
    //carousel setup
    self.carouselView.type = iCarouselTypeLinear;
    self.carouselView.delegate = self;
    self.carouselView.dataSource = self;
    self.carouselView.pagingEnabled = YES;
    self.carouselView.bounceDistance = 0.3;
    
    //self.carouselView.layer.cornerRadius = 4;
    //self.carouselView.layer.masksToBounds = YES; //enable this to restrict the entire carousel to the view specified in the nib
    
    [self.listingObject fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (!error) {
            if ([self.listingObject objectForKey:@"image4"]){
                [self.picIndicator setNumberOfPages:4];
                self.numberOfPics = 4;
                self.firstImage = [self.listingObject objectForKey:@"image1"];
                self.secondImage = [self.listingObject objectForKey:@"image2"];
                self.thirdImage = [self.listingObject objectForKey:@"image3"];
                self.fourthImage = [self.listingObject objectForKey:@"image4"];
            }
            else if ([self.listingObject objectForKey:@"image3"]){
                [self.picIndicator setNumberOfPages:3];
                self.numberOfPics = 3;
                self.firstImage = [self.listingObject objectForKey:@"image1"];
                self.secondImage = [self.listingObject objectForKey:@"image2"];
                self.thirdImage = [self.listingObject objectForKey:@"image3"];
            }
            else if ([self.listingObject objectForKey:@"image2"]) {
                [self.picIndicator setNumberOfPages:2];
                self.numberOfPics = 2;
                self.firstImage = [self.listingObject objectForKey:@"image1"];
                self.secondImage = [self.listingObject objectForKey:@"image2"];
            }
            else{
                [self.picIndicator setHidden:YES];
                self.numberOfPics = 1;
            }
            
            [self.carouselView reloadData];
            
//            self.picView.contentMode = UIViewContentModeScaleAspectFit;
//            [self.picView setFile:[self.listingObject objectForKey:@"image1"]];
//            [self.picView loadInBackground];
//            self.picView.layer.cornerRadius = 4;     //doesn't work due to content mode..
//            self.picView.layer.masksToBounds = YES;
            
            self.titleLabel.text = [self.listingObject objectForKey:@"title"];
            
//            if ([[self.listingObject objectForKey:[NSString stringWithFormat:@"listingPrice%@", self.currency]]intValue]) {
//                int price = [[self.listingObject objectForKey:[NSString stringWithFormat:@"listingPrice%@", self.currency]]intValue];
//                self.priceLabel.text = [NSString stringWithFormat:@"%@%d",self.currencySymbol ,price];
//            }
//            else{
                self.priceLabel.text = @"Negotiable";
//            }
            
            [self.cellArray addObject:self.payCell];
            
            if ([self.listingObject objectForKey:@"condition"]) {
                self.conditionLabel.text = [self.listingObject objectForKey:@"condition"];
                [self.cellArray addObject:self.conditionCell];
            }
            
            if ([self.listingObject objectForKey:@"location"]) {
                NSString *loc = [self.listingObject objectForKey:@"location"];
                self.locationLabel.text = [loc stringByReplacingOccurrencesOfString:@"(null)," withString:@""];
                [self.cellArray addObject:self.locationCell];
            }
            
            if ([self.listingObject objectForKey:@"category"]) {
                if ([[self.listingObject objectForKey:@"category"]isEqualToString:@"Accessories"]) {
                    //do nothing
                }
                else{
                    if ([self.listingObject objectForKey:@"sizeLabel"]) {
                        NSString *sizeNoUK = [[self.listingObject objectForKey:@"sizeLabel"] stringByReplacingOccurrencesOfString:@"UK" withString:@""];
                        
                        if (![self.listingObject objectForKey:@"sizeGender"]) {
                            self.sizeLabel.text = [NSString stringWithFormat:@"%@",sizeNoUK];
                        }
                        else{
                            self.sizeLabel.text = [NSString stringWithFormat:@"%@, %@",[self.listingObject objectForKey:@"sizeGender"], [self.listingObject objectForKey:@"sizeLabel"]];
                        }
                        [self.cellArray addObject:self.sizeCell];
                    }
                }
            }
            
            [self calcPostedDate];
            
            self.idLabel.text = [NSString stringWithFormat:@"ID %@",self.listingObject.objectId];
            [self.cellArray addObject:self.adminCell];

            
            //buyer info
            self.buyer = [self.listingObject objectForKey:@"postUser"];
            
            if ([self.buyer.objectId isEqualToString:[PFUser currentUser].objectId]) {
                [self.longButton setTitle:@"E D I T" forState:UIControlStateNormal];
                [self.longButton setBackgroundColor:[UIColor colorWithRed:0.91 green:0.91 blue:0.91 alpha:1.0]];
                [self.longButton setTitleColor:[UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1.0] forState:UIControlStateNormal];
            }
            else{
                [self.longButton setTitle:@"M E S S A G E  B U Y E R" forState:UIControlStateNormal];
                //not the same buyer
                [self.listingObject incrementKey:@"views"];
                [self.listingObject saveInBackground];
            }
            
            if ([[self.listingObject objectForKey:@"status"]isEqualToString:@"purchased"]) {
                [self.purchasedLabel setHidden:NO];
                [self.purchasedCheckView setHidden:NO];
            }
            else{
                [self.purchasedLabel setHidden:YES];
                [self.purchasedCheckView setHidden:YES];
            }
            
            NSMutableArray *bumpArray = [NSMutableArray arrayWithArray:[self.listingObject objectForKey:@"bumpArray"]];
            if ([bumpArray containsObject:[PFUser currentUser].objectId]) {
                [self.upVoteButton setSelected:YES];
            }
            else{
                [self.upVoteButton setSelected:NO];
            }
            if (bumpArray.count > 0) {
                [self.viewBumpsButton setHidden:NO];
                int count = (int)[bumpArray count];
                [self.upVoteButton setTitle:[NSString stringWithFormat:@"%@",[self abbreviateNumber:count]] forState:UIControlStateNormal];
            }
            else{
                [self.upVoteButton setTitle:@"Tap to Bump!" forState:UIControlStateNormal];
                [self.viewBumpsButton setHidden:YES];
            }
            
            [self setImageBorder];
            [self.buyer fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                if (object) {
                    self.buyernameLabel.text = self.buyer.username;
                    PFFile *pic = [self.buyer objectForKey:@"picture"];
                    
                    UIButton *btn =  [UIButton buttonWithType:UIButtonTypeCustom];
                    btn.frame = CGRectMake(0,0,36,36);
                    [btn addTarget:self action:@selector(buyerPressed) forControlEvents:UIControlEventTouchUpInside];
                    PFImageView *buttonView = [[PFImageView alloc]initWithFrame:btn.frame];
                    [buttonView setBackgroundColor:[UIColor lightGrayColor]];
//                    [buttonView.layer setBorderColor: [[UIColor colorWithRed:0.30 green:0.64 blue:0.99 alpha:1.0] CGColor]];
//                    [buttonView.layer setBorderWidth: 1.0];
                    
                    if (pic != nil) {
                        [buttonView setFile:pic];
                        [buttonView loadInBackground];
                    }
                    else{
                        [buttonView setImage:[UIImage imageNamed:@"empty"]];
                    }

                    [self setImageBorder:buttonView];
                    [btn addSubview:buttonView];
                    self.profileButton = [[UIBarButtonItem alloc] initWithCustomView:btn];
                    
                    if ([[self.listingObject objectForKey:@"status"]isEqualToString:@"purchased"]) {
                        self.navigationItem.rightBarButtonItem = self.profileButton;
                    }
                    else{
                        [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:self.profileButton,infoButton, nil]];
                    }
                }
                else{
                    NSLog(@"buyer error %@", error);
                    [self showAlertWithTitle:@"Buyer not found!" andMsg:nil];
                }
            }];
        }
        else{
            NSLog(@"error fetching listing %@", error);
        }
    }];
    
    [self.tableView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    
    //hide first table view header
    self.tableView.contentInset = UIEdgeInsetsMake(-1.0f, 0.0f, 0.0f, 0.0);
    
    self.buyernameLabel.adjustsFontSizeToFitWidth = YES;
    self.buyernameLabel.minimumScaleFactor=0.5;
    
    self.locationLabel.adjustsFontSizeToFitWidth = YES;
    self.locationLabel.minimumScaleFactor=0.5;
    
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.titleLabel.minimumScaleFactor=0.5;
    
    self.extraLabel.adjustsFontSizeToFitWidth = YES;
    self.extraLabel.minimumScaleFactor=0.5;
    
    self.carouselMainCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.payCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.sizeCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.deliveryCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.locationCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.extraCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.adminCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.buyerinfoCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.buttonCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.conditionCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.spaceCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
}

-(void)viewWillAppear:(BOOL)animated{
    
    [self.navigationController.navigationBar setHidden:NO];

    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Regular" size:13],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    if (self.buttonShowing == NO) {
        [self showBarButton];
    }
    
    if (self.editPressed == YES) {
        [self listingRefresh];
        self.editPressed = NO;
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self hideBarButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

//hide the first header in table view
- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return 1.0f;
    else if(section == 2 || section == 3){
        return 32.0f;
    }
    return 0.0f;
}

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
    return @"";
    
}
-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
   
    if (section == 1 || section == 3 || section == 2)
        return 0.0f;
    return 32.0f;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 30)];

    [headerView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    return headerView;
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 30)];
    [footerView setBackgroundColor:[UIColor colorWithRed:0.965 green:0.969 blue:0.988 alpha:1]];
    return footerView;
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
        return self.cellArray.count;
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
            return self.carouselMainCell;
        }
    }
    else if (indexPath.section == 1){
        if (indexPath.row == 0) {
            if (self.cellArray.count >= 1) {
                return self.cellArray[0];
            }
        }
        else if (indexPath.row == 1) {
            if (self.cellArray.count >= 2) {
                return self.cellArray[1];
            }
        }
        else if (indexPath.row == 2) {
            if (self.cellArray.count >= 3) {
                return self.cellArray[2];
            }
        }
        else if (indexPath.row == 3) {
            if (self.cellArray.count >= 4) {
                return self.cellArray[3];
            }
        }
        else if (indexPath.row == 4) {
            if (self.cellArray.count >= 5) {
                return self.cellArray[4];
            }
        }
        else{
            return nil;
        }
    }
    else if (indexPath.section == 2){
        if (indexPath.row == 0) {
            return self.buttonCell;
        }
    }
    else if (indexPath.section ==3){
        if(indexPath.row == 0){
            return self.spaceCell;
        }
    }
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return 246;
        }
    }
    else if (indexPath.section == 1){
        return 44;
    }
    else if (indexPath.section == 2){
        if (indexPath.row == 0) {
            return 121;
        }
    }
    else if (indexPath.section ==3){
        return 60;
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
        self.postedLabel.text = [NSString stringWithFormat:@"Posted %.fs ago", (minsBetweenDates*60)];
    }
    else if (minsBetweenDates == 1){
        //1 min
        self.postedLabel.text = @"Posted: 1m ago";
    }
    else if (minsBetweenDates > 1 && minsBetweenDates <60){
        //mins
        self.postedLabel.text = [NSString stringWithFormat:@"Posted %.fm ago", minsBetweenDates];
    }
    else if (minsBetweenDates == 60){
        //1 hour
        self.postedLabel.text = @"Posted: 1h ago";
    }
    else if (minsBetweenDates > 60 && minsBetweenDates <1440){
        //hours
        self.postedLabel.text = [NSString stringWithFormat:@"Posted %.fh ago", (minsBetweenDates/60)];
    }
    else if (minsBetweenDates > 1440 && minsBetweenDates < 2880){
        //1 day
        self.postedLabel.text = [NSString stringWithFormat:@"Posted %.fd ago", (minsBetweenDates/1440)];
    }
    else if (minsBetweenDates > 2880 && minsBetweenDates < 10080){
        //days
        self.postedLabel.text = [NSString stringWithFormat:@"Posted %.fd ago", (minsBetweenDates/1440)];
    }
    else if (minsBetweenDates > 10080){
        //weeks
        self.postedLabel.text = [NSString stringWithFormat:@"Posted %.fw ago", (minsBetweenDates/10080)];
    }
    else{
        //fail safe :D
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[NSLocale currentLocale]];
        [dateFormatter setDateFormat:@"MMM YY"];
        
        NSDate *formattedDate = [NSDate date];
        self.postedLabel.text = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:formattedDate]];
        dateFormatter = nil;
    }
}
- (IBAction)saveForLaterPressed:(id)sender {
   
    [self.saveButton setEnabled:NO];
    [[PFUser currentUser] addObject:self.listingObject.objectId forKey:@"savedItems"];
    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            NSLog(@"saved item");
        }
        else{
            NSLog(@"error saving %@", error);
            [self.saveButton setEnabled:YES];
        }
    }];
}

- (IBAction)sharePressed:(id)sender {
    [self hideBarButton];
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self showBarButton];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Share to Facebook Group" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        FBGroupShareViewController *vc = [[FBGroupShareViewController alloc]init];
        vc.objectId = self.listingObject.objectId;
        NavigationController *navigationController = [[NavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:navigationController animated:YES completion:nil];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Share" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSMutableArray *items = [NSMutableArray new];
        [items addObject:[NSString stringWithFormat:@"Check out this WTB: %@ for %@%@\nPosted on Bump http://apple.co/2aY3rBk", [self.listingObject objectForKey:@"title"],self.currency,[self.listingObject objectForKey:[NSString stringWithFormat:@"listingPrice%@", self.currency]]]];
        UIActivityViewController *activityController = [[UIActivityViewController alloc]initWithActivityItems:items applicationActivities:nil];
        [self presentViewController:activityController animated:YES completion:nil];
    }]];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

-(void)BarButtonPressed{
    [self.longButton setEnabled:NO];
    if ([self.buyer.objectId isEqualToString:[PFUser currentUser].objectId]) {
        self.editPressed = YES;
        CreateViewController *vc = [[CreateViewController alloc]init];
        vc.status = @"edit";
        vc.listing = self.listingObject;
        vc.editFromListing = YES;
        NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:^{
            [self.longButton setEnabled:YES];
        }];
    }
    else{
        [self showHUD];
        [self setupMessages];
    }
}

-(void)setupMessages{
    
    PFQuery *convoQuery = [PFQuery queryWithClassName:@"convos"];
    NSString *possID = [NSString stringWithFormat:@"%@%@%@", [PFUser currentUser].objectId, [[self.listingObject objectForKey:@"postUser"]objectId], self.listingObject.objectId];
    NSString *otherId = [NSString stringWithFormat:@"%@%@%@",[[self.listingObject objectForKey:@"postUser"]objectId],[PFUser currentUser].objectId, self.listingObject.objectId];
    NSArray *idArray = [NSArray arrayWithObjects:possID,otherId, nil];
    
    [convoQuery whereKey:@"convoId" containedIn:idArray];
    [convoQuery includeKey:@"buyerUser"];
    [convoQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            //convo exists, goto that one
            MessageViewController *vc = [[MessageViewController alloc]init];
            vc.convoId = [object objectForKey:@"convoId"];
            vc.convoObject = object;
            vc.listing = self.listingObject;
            vc.otherUser = [object objectForKey:@"buyerUser"];
            vc.otherUserName = [[object objectForKey:@"buyerUser"]username];
            [self.longButton setEnabled:YES];
            [self hideHUD];
            [self.navigationController pushViewController:vc animated:YES];
        }
        else{
            //create a new convo and goto it
            NSLog(@"create a new convo");
            
            PFObject *convoObject = [PFObject objectWithClassName:@"convos"];
            convoObject[@"sellerUser"] = [PFUser currentUser];
            convoObject[@"buyerUser"] = [self.listingObject objectForKey:@"postUser"];
            convoObject[@"itemId"] = self.listingObject.objectId;
            convoObject[@"wtbListing"] = self.listingObject;
            convoObject[@"convoId"] = [NSString stringWithFormat:@"%@%@%@",[[self.listingObject objectForKey:@"postUser"]objectId],[PFUser currentUser].objectId, self.listingObject.objectId];
            convoObject[@"totalMessages"] = @0;
            convoObject[@"buyerUnseen"] = @0;
            convoObject[@"sellerUnseen"] = @0;
            [convoObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    //saved
                    MessageViewController *vc = [[MessageViewController alloc]init];
                    vc.convoId = [convoObject objectForKey:@"convoId"];
                    vc.convoObject = convoObject;
                    vc.listing = self.listingObject;
                    vc.userIsBuyer = NO;
                    vc.otherUser = [self.listingObject objectForKey:@"postUser"];
                    vc.otherUserName = [[self.listingObject objectForKey:@"postUser"]username];
                    [self hideHUD];
                    [self.longButton setEnabled:YES];
                    [self.navigationController pushViewController:vc animated:YES];
                }
                else{
                    NSLog(@"error saving convo");
                    [self hideHUD];
                    [self.longButton setEnabled:YES];
                }
            }];
        }
    }];
}

-(void)setImageBorder{
    self.buyerImgView.layer.cornerRadius = 25;
    self.buyerImgView.layer.masksToBounds = YES;
    self.buyerImgView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    self.buyerImgView.contentMode = UIViewContentModeScaleAspectFill;
}

-(void)showAlertView{
    [self hideBarButton];
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self showBarButton];
    }]];
    
    if ([self.buyer.objectId isEqualToString:[PFUser currentUser].objectId]) {
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Delete" message:@"Are you sure you want to delete your listing?" preferredStyle:UIAlertControllerStyleAlert];
            
            [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                [self showBarButton];
            }]];
            [alertView addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                [self.listingObject setObject:@"deleted" forKey:@"status"];
                [self.listingObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    if (succeeded) {
                        [self.navigationController popViewControllerAnimated:YES];
                    }
                }];
            }]];
            
            [self presentViewController:alertView animated:YES completion:nil];
        }]];
        
        if ([[self.listingObject objectForKey:@"status"] isEqualToString:@"purchased"]) {
//                    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Unmark as purchased" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//                        [self.listingObject setObject:@"live" forKey:@"status"];
//                        [self.listingObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
//                            if (succeeded) {
//                                [self.collectionView reloadData];
//                            }
//                        }];
//                    }]];
        }
        else if ([[self.listingObject objectForKey:@"status"] isEqualToString:@"live"]) {
            [actionSheet addAction:[UIAlertAction actionWithTitle:@"Mark as purchased" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                
                UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Mark as purchased" message:@"Are you sure you want to mark your WTB as purchased? Sellers will no longer be able to view your WTB and offer to sell you items" preferredStyle:UIAlertControllerStyleAlert];
                
                [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                    [self showBarButton];
                    
                }]];
                [alertView addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [self showBarButton];
                    [self.listingObject setObject:@"purchased" forKey:@"status"];
                    [self.listingObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                        if (succeeded) {
                            //unhide label
                            self.purchasedLabel.alpha = 0.0;
                            self.purchasedCheckView.alpha = 0.0;
                            
                            [self.purchasedLabel setHidden:NO];
                            [self.purchasedCheckView setHidden:NO];
                            
                            [UIView animateWithDuration:0.5
                                                  delay:0
                                                options:UIViewAnimationOptionCurveEaseIn
                                             animations:^{
                                                 self.purchasedLabel.alpha = 1.0;
                                                 self.purchasedCheckView.alpha = 1.0;
                                                 
                                             }
                                             completion:nil];
                        }
                    }];
                }]];
                [self presentViewController:alertView animated:YES completion:nil];
            }]];
        }
    }
    else{
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Report listing" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            
            UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Report listing" message:@"Bump takes inappropriate behaviour very seriously.\nIf you feel like this post has violated our terms let us know so we can make your experience on Bump as brilliant as possible. Call +447590554897 if you'd like to speak to one of the team immediately." preferredStyle:UIAlertControllerStyleAlert];
            
            [alertView addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                [self showBarButton];
            }]];
            
            [alertView addAction:[UIAlertAction actionWithTitle:@"Report" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                [self showBarButton];
                PFObject *reportObject = [PFObject objectWithClassName:@"Reported"];
                reportObject[@"reportedUser"] = self.buyer;
                reportObject[@"reporter"] = [PFUser currentUser];
                reportObject[@"listing"] = self.listingObject;
                [reportObject saveInBackground];
            }]];
            
            [self presentViewController:alertView animated:YES completion:nil];
            
        }]];
    }
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

-(void)showHUD{
    self.hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    self.hud.square = YES;
    self.hud.mode = MBProgressHUDModeCustomView;
    self.hud.customView = self.spinner;
    [self.spinner startAnimating];
}

-(void)showimageHUD{
    if (!self.imageHud) {
        self.imageHud = [MBProgressHUD showHUDAddedTo:self.picView animated:YES];
    }
    self.imageHud.square = YES;
    self.imageHud.mode = MBProgressHUDModeCustomView;
    self.imageHud.color = [UIColor whiteColor];
    
    if (!self.imageSpinner) {
       self.imageSpinner = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeBallClipRotateMultiple tintColor:[UIColor lightGrayColor] size:20.0f];
    }
    
    self.imageHud.customView = self.imageSpinner;
    [self.imageSpinner startAnimating];
}

-(void)hideImageHud{
    [self.imageSpinner stopAnimating];
    [MBProgressHUD hideHUDForView:self.picView animated:NO];
    self.imageSpinner = nil;
    self.imageHud = nil;
}

-(void)hideHUD{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow animated:YES];
    });
}

-(void)buyerPressed{
    UserProfileController *vc = [[UserProfileController alloc]init];
    vc.user = self.buyer;
    [self.navigationController pushViewController:vc animated:YES];
}
- (IBAction)upvotePressed:(id)sender {
    
    [Answers logCustomEventWithName:@"Bumped a listing"
                   customAttributes:@{
                                      @"where":@"Listing"
                                      }];
    
    NSMutableArray *bumpArray = [NSMutableArray arrayWithArray:[self.listingObject objectForKey:@"bumpArray"]];
    if ([bumpArray containsObject:[PFUser currentUser].objectId]) {
        NSLog(@"already bumped it m8");
        [self.upVoteButton setSelected:NO];
        [bumpArray removeObject:[PFUser currentUser].objectId];
        [self.listingObject setObject:bumpArray forKey:@"bumpArray"];
        [self.listingObject incrementKey:@"bumpCount" byAmount:@-1];
    }
    else{
        NSLog(@"bumped");
        [self.upVoteButton setSelected:YES];
        [bumpArray addObject:[PFUser currentUser].objectId];
        [self.listingObject addObject:[PFUser currentUser].objectId forKey:@"bumpArray"];
        [self.listingObject incrementKey:@"bumpCount"];
        NSString *pushText = [NSString stringWithFormat:@"%@ just bumped your listing 👊", [PFUser currentUser].username];
        
        if (![self.buyer.objectId isEqualToString:[PFUser currentUser].objectId]) {
            NSDictionary *params = @{@"userId": [[self.listingObject objectForKey:@"postUser"]objectId], @"message": pushText, @"sender": [PFUser currentUser].username, @"bumpValue": @"NO", @"listingID": self.listingObject.objectId};
            
            [PFCloud callFunctionInBackground:@"sendNewPush" withParameters:params block:^(NSDictionary *response, NSError *error) {
                if (!error) {
                    NSLog(@"push response %@", response);
                }
                else{
                    NSLog(@"push error %@", error);
                }
            }];
        }
        else{
            [Answers logCustomEventWithName:@"Bumped own listing"
                           customAttributes:@{
                                              @"where":@"Listing"
                                              }];
        }
    }
    [self.listingObject saveInBackground];
    if (bumpArray.count > 0) {
        [self.viewBumpsButton setHidden:NO];
        int count = (int)[bumpArray count];
        [self.upVoteButton setTitle:[NSString stringWithFormat:@"%@",[self abbreviateNumber:count]] forState:UIControlStateNormal];
    }
    else{
        [self.viewBumpsButton setHidden:YES];
        [self.upVoteButton setTitle:@"Tap to Bump!" forState:UIControlStateNormal];
    }
}

-(NSString *)abbreviateNumber:(int)num {
    
    NSString *abbrevNum;
    float number = (float)num;
    
    //Prevent numbers smaller than 1000 to return NULL
    if (num >= 1000) {
        NSArray *abbrev = @[@"K", @"M", @"B"];
        
        for (int i = (int)abbrev.count - 1; i >= 0; i--) {
            
            // Convert array index to "1000", "1000000", etc
            int size = pow(10,(i+1)*3);
            
            if(size <= number) {
                // Removed the round and dec to make sure small numbers are included like: 1.1K instead of 1K
                number = number/size;
                NSString *numberString = [self floatToString:number];
                
                // Add the letter for the abbreviation
                abbrevNum = [NSString stringWithFormat:@"%@%@", numberString, [abbrev objectAtIndex:i]];
            }
        }
    } else {
        
        // Numbers like: 999 returns 999 instead of NULL
        abbrevNum = [NSString stringWithFormat:@"%d", (int)number];
    }
    
    return abbrevNum;
}

- (NSString *) floatToString:(float) val {
    NSString *ret = [NSString stringWithFormat:@"%.1f", val];
    unichar c = [ret characterAtIndex:[ret length] - 1];
    
    while (c == 48) { // 0
        ret = [ret substringToIndex:[ret length] - 1];
        c = [ret characterAtIndex:[ret length] - 1];
        
        //After finding the "." we know that everything left is the decimal number, so get a substring excluding the "."
        if(c == 46) { // .
            ret = [ret substringToIndex:[ret length] - 1];
        }
    }
    return ret;
}
- (IBAction)viewbumpsPressed:(id)sender {
    if (![self.buyer.objectId isEqualToString:[PFUser currentUser].objectId]) {
        [Answers logCustomEventWithName:@"View Bumps"
                       customAttributes:@{
                                          @"own listing":@"NO"
                                          }];
    }
    else{
        [Answers logCustomEventWithName:@"View Bumps"
                       customAttributes:@{
                                          @"own listing":@"YES"
                                          }];
    }

    whoBumpedTableView *vc = [[whoBumpedTableView alloc]init];
    vc.bumpArray = [self.listingObject objectForKey:@"bumpArray"];
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)setImageBorder:(UIImageView *)imageView{
    imageView.layer.cornerRadius = imageView.frame.size.width / 2;
    imageView.layer.masksToBounds = YES;
    imageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    imageView.contentMode = UIViewContentModeScaleAspectFill;
}

-(void)listingRefresh{
    [self.cellArray removeAllObjects];
    NSLog(@"REFRESHING");
    [self.listingObject fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (!error) {
            if ([self.listingObject objectForKey:@"image4"]){
                [self.picIndicator setNumberOfPages:4];
                [self.picIndicator setHidden:NO];
                self.numberOfPics = 4;
                self.firstImage = [self.listingObject objectForKey:@"image1"];
                self.secondImage = [self.listingObject objectForKey:@"image2"];
                self.thirdImage = [self.listingObject objectForKey:@"image3"];
                self.fourthImage = [self.listingObject objectForKey:@"image4"];
            }
            else if ([self.listingObject objectForKey:@"image3"]){
                [self.picIndicator setNumberOfPages:3];
                self.numberOfPics = 3;
                [self.picIndicator setHidden:NO];
                self.firstImage = [self.listingObject objectForKey:@"image1"];
                self.secondImage = [self.listingObject objectForKey:@"image2"];
                self.thirdImage = [self.listingObject objectForKey:@"image3"];
            }
            else if ([self.listingObject objectForKey:@"image2"]) {
                [self.picIndicator setNumberOfPages:2];
                self.numberOfPics = 2;
                [self.picIndicator setHidden:NO];
                self.firstImage = [self.listingObject objectForKey:@"image1"];
                self.secondImage = [self.listingObject objectForKey:@"image2"];
            }
            else{
                [self.picIndicator setHidden:YES];
                self.numberOfPics = 1;
            }
            
            [self.carouselView reloadData];
            
//            self.picView.contentMode = UIViewContentModeScaleAspectFit;
//            [self.picView setFile:[self.listingObject objectForKey:@"image1"]];
//            [self.picView loadInBackground];
            
            self.titleLabel.text = [self.listingObject objectForKey:@"title"];
            
//            if ([[self.listingObject objectForKey:[NSString stringWithFormat:@"listingPrice%@", self.currency]]intValue]) {
//                int price = [[self.listingObject objectForKey:[NSString stringWithFormat:@"listingPrice%@", self.currency]]intValue];
//                self.priceLabel.text = [NSString stringWithFormat:@"%@%d",self.currencySymbol ,price];
//            }
//            else{
                self.priceLabel.text = @"Negotiable";
//            }
            
            [self.cellArray addObject:self.payCell];
            
            if ([self.listingObject objectForKey:@"condition"]) {
                self.conditionLabel.text = [self.listingObject objectForKey:@"condition"];
                [self.cellArray addObject:self.conditionCell];
            }
            
            if ([self.listingObject objectForKey:@"geopoint"]) {
                NSString *loc = [self.listingObject objectForKey:@"location"];
                self.locationLabel.text = [loc stringByReplacingOccurrencesOfString:@"(null)," withString:@""];
                [self.cellArray addObject:self.locationCell];
            }
            
            if ([self.listingObject objectForKey:@"category"]) {
                if ([[self.listingObject objectForKey:@"category"]isEqualToString:@"Accessories"]) {
                    //do nothing
                }
                else{
                    if ([self.listingObject objectForKey:@"sizeLabel"]) {
                        NSString *sizeNoUK = [[self.listingObject objectForKey:@"sizeLabel"] stringByReplacingOccurrencesOfString:@"UK" withString:@""];
                        
                        if (![self.listingObject objectForKey:@"sizeGender"]) {
                            self.sizeLabel.text = [NSString stringWithFormat:@"%@",sizeNoUK];
                        }
                        else{
                            self.sizeLabel.text = [NSString stringWithFormat:@"%@, %@",[self.listingObject objectForKey:@"sizeGender"], [self.listingObject objectForKey:@"sizeLabel"]];
                        }
                        [self.cellArray addObject:self.sizeCell];
                    }
                }
            }
            
            self.idLabel.text = [NSString stringWithFormat:@"ID %@",self.listingObject.objectId];
            [self.cellArray addObject:self.adminCell];
        }
        [self.tableView reloadData];
    }];
}

-(void)hideBarButton{
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [self.longButton setAlpha:0.0];
                     }
                     completion:^(BOOL finished) {
                         self.buttonShowing = NO;
                     }];
}

-(void)showBarButton{
    self.longButton.alpha = 0.0f;
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.longButton.alpha = 1.0f;
                     }
                     completion:^(BOOL finished) {
                         self.buttonShowing = YES;
                     }];
}

#pragma mark - carousel delegates

- (NSInteger)numberOfItemsInCarousel:(__unused iCarousel *)carousel
{
    return self.numberOfPics;
}

- (UIView *)carousel:(__unused iCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    
    //create new view if no view is available for recycling
    if (view == nil)
    {
        view = [[PFImageView alloc] initWithFrame:CGRectMake(0, 0, self.carouselView.frame.size.width,self.carouselView.frame.size.height)];
        view.contentMode = UIViewContentModeScaleAspectFit;
    }
    if (index == 0) {
        [((PFImageView *)view)setFile:[self.listingObject objectForKey:@"image1"]];
    }
    else if (index == 1){
        [((PFImageView *)view)setFile:[self.listingObject objectForKey:@"image2"]];
    }
    else if (index == 2){
        [((PFImageView *)view)setFile:[self.listingObject objectForKey:@"image3"]];
    }
    else if (index == 3){
        [((PFImageView *)view)setFile:[self.listingObject objectForKey:@"image4"]];
    }    
    [((PFImageView *)view) loadInBackground];
    
    return view;
}

- (void)carouselDidEndScrollingAnimation:(iCarousel *)carousel{
    self.picIndicator.currentPage = self.carouselView.currentItemIndex;
}

- (NSInteger)numberOfPlaceholdersInCarousel:(__unused iCarousel *)carousel
{
    //note: placeholder views are only displayed on some carousels if wrapping is disabled
    return 2;
}

- (UIView *)carousel:(__unused iCarousel *)carousel placeholderViewAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    if (view == nil)
    {
        view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.carouselView.frame.size.width,self.carouselView.frame.size.height)];
        view.contentMode = UIViewContentModeCenter;
        view.backgroundColor = [UIColor whiteColor];
    }
    return view;
}

- (void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index{
    
    DetailImageController *vc = [[DetailImageController alloc]init];
    vc.listingPic = YES;
    vc.chosenIndex = (int)index;
    vc.delegate = self;
    
    if (self.numberOfPics == 1) {
        vc.numberOfPics = 1;
        vc.listing = self.listingObject;
    }
    else if (self.numberOfPics == 2){
        vc.numberOfPics = 2;
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
    [self hideBarButton];
    [self.navigationController presentViewController:vc animated:YES completion:nil];
    
}

-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Got it" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)dismissedDetailImageView{
    NSLog(self.buttonShowing ? @"YES":@"NO");
    [self showBarButton];
}


@end
