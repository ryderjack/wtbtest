//
//  simpleCreateVC.m
//  wtbtest
//
//  Created by Jack Ryder on 25/01/2017.
//  Copyright © 2017 Jack Ryder. All rights reserved.
//

#import "simpleCreateVC.h"
#import "UIImage+Resize.h"
#import "FBGroupShareViewController.h"
#import <Crashlytics/Crashlytics.h>
#import "AppDelegate.h"
#import "ForSaleListing.h"
#import "ForSaleCell.h"
#import "CreateViewController.h"

@interface simpleCreateVC ()

@end

@implementation simpleCreateVC

- (void)viewDidLoad {
    [super viewDidLoad];

    self.titleTextLabel.delegate = self;
    self.photostotal = 0;
    self.buyNowArray = [NSMutableArray array];
    self.buyNowIDs = [NSMutableArray array];
    self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
    
    self.finishedListing = YES;
    self.tapNumber = 0;
    
    [self useCurrentLoc];
    
    self.profanityList = @[@"fucking",@"shitting", @"cunt", @"wanker", @"nigger", @"penis", @"cock", @"dick", @"bastard"];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(toggleKeyboard)];
    tap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tap];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated{
    [self.navigationController.navigationBar setHidden:YES];
    
    if (self.introMode == YES) {
        [self.skipButton setHidden:NO];
    }
    else{
        [self.skipButton setHidden:YES];
    }
    
    if (![PFUser currentUser]) {
        WelcomeViewController *vc = [[WelcomeViewController alloc]init];
        NavigationController *navController = [[NavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:navController animated:YES completion:nil];
    }
    else{
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
    }
    
    self.imageSource = @"";
    
    [Answers logCustomEventWithName:@"Viewed page"
                   customAttributes:@{
                                      @"pageName":@"Create Listing"
                                      }];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    if (self.introMode != YES && self.finishedListing == YES) {
        [self.titleTextLabel becomeFirstResponder];
    }
    
    if (self.setupYes != YES) {
        [self setUpSuccess];
    }
    
    if (self.introMode == YES && self.shownPushAlert != YES) {
        //show prompt for enabling push
        [self showPushAlert];
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    if (self.hudShowing == YES) {
        [self hidHUD];
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if(textField == self.titleTextLabel){
        if(range.length + range.location > textField.text.length)
        {
            return NO;
        }
        
        NSUInteger newLength = [textField.text length] + [string length] - range.length;
        return newLength <= 50;
    }
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    if (textField == self.titleTextLabel) {
        NSArray *words = [textField.text componentsSeparatedByString:@" "];
        for (NSString *string in words) {
            if ([self.profanityList containsObject:string.lowercaseString]) {
                textField.text = @"";
            }
        }
    }
    
    NSString *stringCheck = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (![stringCheck isEqualToString:@""]) {
        self.finishedListing = NO;
        [self showGoogle];
    }
}

-(void)showGoogle{
    NSString *searchString = [self.titleTextLabel.text stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    NSString *URLString = [NSString stringWithFormat:@"https://www.google.co.uk/search?tbm=isch&q=%@&tbs=iar:s#imgrc=_",searchString];
    
    self.JRWebView = [[TOJRWebView alloc] initWithURL:[NSURL URLWithString:URLString]];
    self.JRWebView.title = @"A D D  I M A G E";
    self.JRWebView.showUrlWhileLoading = NO;
    self.JRWebView.showPageTitles = NO;
    self.JRWebView.delegate = self;
    self.JRWebView.createMode = YES;
    
    NavigationController *navigationController = [[NavigationController alloc] initWithRootViewController:self.JRWebView];
    [self presentViewController:navigationController animated:YES completion:nil];
}

-(void)paidPressed{
    //do nothing
}

-(void)cameraPressed{
    //launch image picker
    [Answers logCustomEventWithName:@"camera tapped"
                   customAttributes:@{
                                      @"where":@"create"
                                      }];
    [self alertSheet];
}

-(void)cancelWebPressed{
    [Answers logCustomEventWithName:@"Aborted listing"
                   customAttributes:@{
                                      @"where":@"create"
                                      }];
    self.finishedListing = YES;
    self.titleTextLabel.text = @"";
    [self.JRWebView dismissViewControllerAnimated:YES completion:nil];
}

-(void)screeshotPressed:(UIImage *)screenshot withTaps:(int)taps{
    [Answers logCustomEventWithName:@"Add image from Google"
                   customAttributes:@{
                                      @"where":@"create"
                                      }];
    self.tapNumber = taps;
    
//    if (taps == 1 || taps == 2) {
//        //aleady been auto cropped
//        [self.JRWebView dismissViewControllerAnimated:YES completion:nil];
//        [self finalImage:screenshot];
//    }
//    else{
        [self displayCropperWithImage:screenshot];
//    }
}

-(void)alertSheet{
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Take a picture" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [Answers logCustomEventWithName:@"Take a picture tapped"
                       customAttributes:@{
                                          @"where":@"create"
                                          }];
        [self dismissViewControllerAnimated:YES completion:^{
            CameraController *vc = [[CameraController alloc]init];
            vc.delegate = self;
            vc.offerMode = NO;
            self.shouldSave = YES;
            [self presentViewController:vc animated:YES completion:nil];
        }];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Choose from library" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [Answers logCustomEventWithName:@"Choose pictures tapped"
                       customAttributes:@{
                                          @"where":@"create"
                                          }];
//        [self dismissViewControllerAnimated:YES completion:^{
            if (!self.picker) {
                self.picker = [[UIImagePickerController alloc] init];
                self.picker.delegate = self;
                self.picker.allowsEditing = NO;
                self.picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            }
            [self.JRWebView presentViewController:self.picker animated:YES completion:nil];
//        }];
    }]];
    
    [self.JRWebView presentViewController:actionSheet animated:YES completion:nil];
}

#pragma mark - various image picker delegate methods
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
    //display crop picker
    [picker dismissViewControllerAnimated:YES completion:^{
        [self displayCropperWithImage:chosenImage];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

-(void)displayCropperWithImage:(UIImage *)image{
    BASSquareCropperViewController *squareCropperViewController = [[BASSquareCropperViewController alloc] initWithImage:image minimumCroppedImageSideLength:375.0f];
    squareCropperViewController.squareCropperDelegate = self;
    squareCropperViewController.backgroundColor = [UIColor whiteColor];
    squareCropperViewController.borderColor = [UIColor whiteColor];
    squareCropperViewController.doneFont = [UIFont fontWithName:@"PingFangSC-Regular" size:18.0f];
    squareCropperViewController.cancelFont = [UIFont fontWithName:@"PingFangSC-Regular" size:16.0f];
    squareCropperViewController.excludedBackgroundColor = [UIColor blackColor];
    squareCropperViewController.tapNumber = self.tapNumber;
    [self.JRWebView presentViewController:squareCropperViewController animated:YES completion:nil];
}

- (void)squareCropperDidCropImage:(UIImage *)croppedImage inCropper:(BASSquareCropperViewController *)cropper{
    [self.JRWebView dismissViewControllerAnimated:NO completion:^{
        [self.JRWebView dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [self finalImage:croppedImage];
}

- (void)squareCropperDidCancelCropInCropper:(BASSquareCropperViewController *)cropper{
    [cropper dismissViewControllerAnimated:YES completion:NULL];
}

-(void)dismissPressed:(BOOL)yesorno{
    //camera dismissed
    self.titleTextLabel.text = @"";
    [self.titleTextLabel becomeFirstResponder];
}

-(void)tagString:(NSString *)tag{
    //do nothing
}
-(void)finalImage:(UIImage *)image{
    //save image if just been taken
    UIImage *newImage = [image resizedImage:CGSizeMake(750.00, 750.00) interpolationQuality:kCGInterpolationHigh];

    if (self.shouldSave == YES) {
        UIImageWriteToSavedPhotosAlbum(newImage, nil, nil, nil);
        self.shouldSave = NO;
    }
    self.firstImage = newImage;
    self.photostotal ++;
    
    [self saveListing];
}

-(void)setUpSuccess{
    self.successView = nil;
    self.bgView = nil;
    
    self.completionShowing = YES;
    self.setupYes = YES;
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SuccessView" owner:self options:nil];
    self.successView = (CreateSuccessView *)[nib objectAtIndex:0];
    self.successView.delegate = self;
    self.successView.alpha = 0.0;
    [self.successView setCollectionViewDataSourceDelegate:self indexPath:nil];
    [self.navigationController.view addSubview:self.successView];
    
    if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
        //iphone5
        [self.successView setFrame:CGRectMake((self.view.frame.size.width/2)-150, -460, 300, 460)];
    }
    else{
        [self.successView setFrame:CGRectMake((self.view.frame.size.width/2)-170, -480, 340, 480)]; //iPhone 6/7 specific
    }
    
    self.successView.layer.cornerRadius = 10;
    self.successView.layer.masksToBounds = YES;
    
    self.bgView = [[UIView alloc]initWithFrame:self.view.frame];
    self.bgView.backgroundColor = [UIColor blackColor];
    self.bgView.alpha = 0.0;
    [self.navigationController.view insertSubview:self.bgView belowSubview:self.successView];
}

-(void)showSuccess{
    self.bgView.alpha = 0.8;
    [self.successView setAlpha:1.0];
    [UIView animateWithDuration:1.5
                          delay:0.0
         usingSpringWithDamping:0.5
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                                //iphone5
                                [self.successView setFrame:CGRectMake(0, 0, 300, 460)];
                            }
                            else{
                                [self.successView setFrame:CGRectMake(0, 0, 340, 480)];
                            }
                            self.successView.center = self.view.center;
                        }
                     completion:^(BOOL finished) {
                         
                     }];
}

-(void)hideSuccess{
    self.finishedListing = YES;
    [UIView animateWithDuration:1.0
                          delay:0.0
         usingSpringWithDamping:0.1
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                                //iphone5
                                [self.successView setFrame:CGRectMake((self.view.frame.size.width/2)-150,1000, 300, 460)];
                            }
                            else{
                                [self.successView setFrame:CGRectMake((self.view.frame.size.width/2)-170,1000, 340, 480)]; //iPhone 6/7 specific
                            }
                            [self.bgView setAlpha:0.0];
                        }
                     completion:^(BOOL finished) {
                         //Completion Block
                         self.completionShowing = NO;
                         [self.successView setAlpha:0.0];
                         
                         if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                             //iphone5
                             [self.successView setFrame:CGRectMake((self.view.frame.size.width/2)-150, -460, 300, 460)];
                         }
                         else{
                             [self.successView setFrame:CGRectMake((self.view.frame.size.width/2)-170, -480, 340, 480)]; //iPhone 6/7 specific
                         }
                     }];
}

-(void)sharePressed{
    [Answers logCustomEventWithName:@"Success Share pressed"
                   customAttributes:@{
                                      @"pageName":@"create"
                                      }];
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Share to Facebook Group" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        FBGroupShareViewController *vc = [[FBGroupShareViewController alloc]init];
        vc.objectId = self.listing.objectId;
        NavigationController *navigationController = [[NavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:navigationController animated:YES completion:nil];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Share" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSMutableArray *items = [NSMutableArray new];
        [items addObject:[NSString stringWithFormat:@"Check out my wanted listing: %@ for %@%@\nPosted on Bump http://apple.co/2aY3rBk", [self.listing objectForKey:@"title"],self.currency,[self.listing objectForKey:[NSString stringWithFormat:@"listingPrice%@", self.currency]]]];
        UIActivityViewController *activityController = [[UIActivityViewController alloc]initWithActivityItems:items applicationActivities:nil];
        [self presentViewController:activityController animated:YES completion:nil];
    }]];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

-(void)successDonePressed{
    [Answers logCustomEventWithName:@"Success Done pressed"
                   customAttributes:@{
                                      @"pageName":@"create"
                                      }];
    [self hideSuccess];
    
    if (self.introMode == YES) {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
    else{
        [self resetAll];
        self.tabBarController.selectedIndex = 1;
    }
}

-(void)createPressed{
    [Answers logCustomEventWithName:@"Success Create pressed"
                   customAttributes:@{
                                      @"pageName":@"create"
                                      }];
    [self resetAll];
    [self.titleTextLabel becomeFirstResponder];
    [self hideSuccess];
}

-(void)editPressed{
    [Answers logCustomEventWithName:@"Success Edit pressed"
                   customAttributes:@{
                                      @"pageName":@"create"
                                      }];
    //show edit VC
    CreateViewController *vc = [[CreateViewController alloc]init];
    vc.status = @"edit";
    vc.listing = self.listing;
    vc.addDetails = YES;
    if (self.introMode == YES) {
        vc.introMode = YES;
    }
    NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

-(void)addMorePressed{
    [Answers logCustomEventWithName:@"Success Add more pressed"
                   customAttributes:@{
                                      @"pageName":@"create"
                                      }];
    //show edit VC
    CreateViewController *vc = [[CreateViewController alloc]init];
    vc.status = @"edit";
    vc.listing = self.listing;
    vc.addDetails = YES;
    if (self.introMode == YES) {
        vc.introMode = YES;
    }
    NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

-(NSInteger)collectionView:(UICollectionView *)collectionView
    numberOfItemsInSection:(NSInteger)section
{
    return self.buyNowArray.count;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == self.buyNowArray.count-1 && self.buyNowArray.count > 1) {
        
        [Answers logCustomEventWithName:@"Tapped 'view more' after creating listing"
                       customAttributes:@{}];
        
        if (self.introMode == YES) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"viewMorePressed"];
            [self.navigationController dismissViewControllerAnimated:YES completion:^{
                AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                appDelegate.tabBarController.selectedIndex = 1;
            }];
        }
        else{
            self.tabBarController.selectedIndex = 1;
            [self successDonePressed];
        }
    }
    else{
        [Answers logCustomEventWithName:@"Tapped for sale listing after creating listing"
                       customAttributes:@{}];
        
        PFObject *WTS = [self.buyNowArray objectAtIndex:indexPath.item];
        ForSaleListing *vc = [[ForSaleListing alloc]init];
        vc.listingObject = WTS;
        vc.WTBObject = self.listing;
        vc.source = @"create";
        vc.pureWTS = NO;
        NavigationController *nav = [[NavigationController alloc]initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:nil];
    }
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                 cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ForSaleCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    cell.itemView.image = nil;
    
    if (indexPath.row == self.buyNowArray.count-1 && self.buyNowArray.count > 1) {
        [cell.itemView setImage:[UIImage imageNamed:@"viewMore"]];
    }
    else{
        PFObject *WTS = [self.buyNowArray objectAtIndex:indexPath.item];
        //        NSLog(@"WTS: %@ at index: %ld", WTS, (long)indexPath.row);
        //setup cell
        [cell.itemView setFile:[WTS objectForKey:@"thumbnail"]];
        [cell.itemView loadInBackground];
    }
    
    cell.itemView.layer.cornerRadius = 35;
    cell.itemView.layer.masksToBounds = YES;
    cell.itemView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    cell.itemView.contentMode = UIViewContentModeScaleAspectFill;
    
    return cell;
}

-(void)resetAll{
    self.somethingChanged = NO;
    self.titleTextLabel.text = @"";
    self.photostotal = 0;
    self.geopoint = nil;
    self.listing = nil;
}

-(void)useCurrentLoc{
    [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint * _Nullable geoPoint, NSError * _Nullable error) {
        if (!error) {
            double latitude = geoPoint.latitude;
            double longitude = geoPoint.longitude;
            
            CLLocation *loc = [[CLLocation alloc]initWithLatitude:latitude longitude:longitude];
            CLGeocoder *geocoder = [[CLGeocoder alloc]init];
            [geocoder reverseGeocodeLocation:loc completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
                if (placemarks) {
                    CLPlacemark *placemark = [placemarks lastObject];
                    self.locationString = [NSString stringWithFormat:@"%@, %@", placemark.locality, placemark.administrativeArea];
                    
                    if (geoPoint) {
                        self.geopoint = geoPoint;
                    }
                    else{
                        NSLog(@"error with location");
                    }
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

-(void)showHUD{
    self.hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    self.hud.square = YES;
    self.hud.mode = MBProgressHUDModeCustomView;
    self.hud.customView = self.spinner;
    [self.spinner startAnimating];
    self.hudShowing = YES;
    self.shouldShowHUD = YES;
}

-(void)hidHUD{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow animated:YES];
        self.hudShowing = NO;
        self.shouldShowHUD = NO;
    });
}

-(void)saveListing{
    [self showHUD];
    
    NSString *itemTitle = [self.titleTextLabel.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    self.listing =[PFObject objectWithClassName:@"wantobuys"];
    
    [self.listing setObject:itemTitle forKey:@"title"];
    [self.listing setObject:[itemTitle lowercaseString]forKey:@"titleLower"];
    
    //save keywords (minus useless words)
    NSArray *wasteWords = [NSArray arrayWithObjects:@"x",@"to",@"with",@"and",@"the",@"wtb",@"or",@" ",@".",@"very",@"interested", @"in",@"wanted", @"", @"all",@"any", @"&",@"looking",@"size", @"buy", @"these", @"this", @"that", @"-",@"(", @")",@"/", nil];
    NSString *title = [itemTitle lowercaseString];
    NSArray *strings = [title componentsSeparatedByString:@" "];
    NSMutableArray *mutableStrings = [NSMutableArray arrayWithArray:strings];
    [mutableStrings removeObjectsInArray:wasteWords];
    
    if ([mutableStrings containsObject:@"bogo"]) {
        [mutableStrings addObject:@"box"];
        [mutableStrings addObject:@"logo"];
    }
    
    if ([mutableStrings containsObject:@"tee"]) {
        [mutableStrings addObject:@"t"];
        [mutableStrings addObject:@"t-shirt"];
    }
    
    if ([mutableStrings containsObject:@"camo"]) {
        [mutableStrings addObject:@"camouflage"];
    }
    
    if ([mutableStrings containsObject:@"hoodie"]) {
        [mutableStrings addObject:@"hoody"];
    }
    
    if ([mutableStrings containsObject:@"crew"]) {
        [mutableStrings addObject:@"crewneck"];
        [mutableStrings addObject:@"sweatshirt"];
        [mutableStrings addObject:@"sweater"];
        [mutableStrings addObject:@"sweat"];
    }
    
    [self.listing setObject:mutableStrings forKey:@"keywords"];
    [self.listing setObject:@"live" forKey:@"status"];
    
    //expiration in 2 weeks
    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
    dayComponent.minute = 1;
    NSCalendar *theCalendar = [NSCalendar currentCalendar];
    NSDate *expirationDate = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
    [self.listing setObject:expirationDate forKey:@"expiration"];

    if (self.geopoint != nil) {
        [self.listing setObject:self.locationString forKey:@"location"];
        [self.listing setObject:self.geopoint forKey:@"geopoint"];
    }

    [self.listing setObject:@0 forKey:@"views"];
    [self.listing setObject:@0 forKey:@"bumpCount"];
    [self.listing setObject:self.currency forKey:@"currency"];
    [self.listing setObject:[PFUser currentUser] forKey:@"postUser"];
    
    NSData* data = UIImageJPEGRepresentation(self.firstImage, 0.7f);
    
    if (data == nil) {
        [Answers logCustomEventWithName:@"PFFile Nil Data"
                       customAttributes:@{
                                          @"pageName":@"simpleCreateVC"
                                          }];
        
        //prevent crash when creating a PFFile with nil data
        [self hidHUD];
        [self showAlertWithTitle:@"Image Error" andMsg:@"Woops, something went wrong! Please try again"];
        return;
    }
    
    PFFile *imageFile1 = [PFFile fileWithName:@"Image1.jpg" data:data];
    [self.listing setObject:imageFile1 forKey:@"image1"];
    
    [self.listing saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            
            NSLog(@"listing saved! %@", self.listing.objectId);
            
            [self findRelevantItems];
            
            //analytics
            if (self.introMode == YES) {
                [Answers logCustomEventWithName:@"Listing Complete"
                               customAttributes:@{
                                                  @"mode":@"Intro",
                                                  @"imageSource":self.imageSource
                                                  }];
            }
            else{
                [Answers logCustomEventWithName:@"Listing Complete"
                               customAttributes:@{
                                                  @"mode":@"Normal",
                                                  @"imageSource":self.imageSource
                                                  }];
            }

            //add listing to home page via notif.
            [[NSNotificationCenter defaultCenter] postNotificationName:@"justPostedListing" object:self.listing];
            [[PFUser currentUser]incrementKey:@"postNumber"];
            [[PFUser currentUser] saveInBackground];
            
            //schedule local notif. for first listing
            if (![[PFUser currentUser] objectForKey:@"postNumber"]) {
                
                //local notifications set up
                NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
                dayComponent.day = 2;
                NSCalendar *theCalendar = [NSCalendar currentCalendar];
                NSDate *dateToFire = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
                
                UILocalNotification *localNotification = [[UILocalNotification alloc]init];
                [localNotification setAlertBody:@"Congrats on your first wanted listing! Swipe to browse recommended items that you can purchase on Bump"];
                [localNotification setFireDate: dateToFire];
                [localNotification setTimeZone: [NSTimeZone defaultTimeZone]];
                [localNotification setRepeatInterval: 0];
                [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
            }
            
            //send FB friends a push asking them to Bump listing!
            NSString *pushText = [NSString stringWithFormat:@"Your Facebook friend %@ just posted a listing - Tap to Bump it 👊", [[PFUser currentUser] objectForKey:@"fullname"]];
            
            PFQuery *bumpedQuery = [PFQuery queryWithClassName:@"Bumped"];
            [bumpedQuery whereKey:@"facebookId" containedIn:[[PFUser currentUser]objectForKey:@"friends"]];
            [bumpedQuery whereKey:@"safeDate" lessThanOrEqualTo:[NSDate date]]; //CHANGE
            [bumpedQuery whereKeyExists:@"user"];
            [bumpedQuery includeKey:@"user"];
            bumpedQuery.limit = 10;
            [bumpedQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                if (objects) {
                    NSLog(@"these objects can be pushed to %@", objects);
                    if (objects.count > 0) {
                        //create safe date which is 3 days from now
                        NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
                        dayComponent.day = 3;
                        NSCalendar *theCalendar = [NSCalendar currentCalendar];
                        NSDate *safeDate = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
                        
                        for (PFObject *bumpObj in objects) {
                            [bumpObj setObject:safeDate forKey:@"safeDate"];
                            [bumpObj incrementKey:@"timesBumped"];
                            [bumpObj saveInBackground];
                            PFUser *friendUser = [bumpObj objectForKey:@"user"];
                            
                            NSDictionary *params = @{@"userId": friendUser.objectId, @"message": pushText, @"sender": [PFUser currentUser].username, @"bumpValue": @"YES", @"listingID": self.listing.objectId};
                            
                            [PFCloud callFunctionInBackground:@"sendNewPush" withParameters:params block:^(NSDictionary *response, NSError *error) {
                                if (!error) {
                                    NSLog(@"push response %@", response);
                                    [Answers logCustomEventWithName:@"Sent FB Friend a Bump Push"
                                                   customAttributes:@{}];
                                }
                                else{
                                    NSLog(@"push error %@", error);
                                }
                            }];
                        }
                    }
                }
                else{
                    NSLog(@"error finding relevant bumped obj's %@", error);
                }
            }];
            
            //update wanted words from previous 10 listings
            PFQuery *myPosts = [PFQuery queryWithClassName:@"wantobuys"];
            [myPosts whereKey:@"postUser" equalTo:[PFUser currentUser]];
            [myPosts orderByDescending:@"createdAt"];
            myPosts.limit = 10;
            [myPosts findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                if (objects) {
                    NSMutableArray *wantedWords = [NSMutableArray array];
                    
                    for (PFObject *listing in objects) {
                        NSArray *keywords = [listing objectForKey:@"keywords"];
                        
                        for (NSString *word in keywords) {
                            if (![wantedWords containsObject:word]) {
                                [wantedWords addObject:word];
                            }
                        }
                    }
                    [[PFUser currentUser] setObject:wantedWords forKey:@"wantedWords"];
                    [[PFUser currentUser] saveInBackground];
                }
                else{
                    NSLog(@"nee posts pet");
                }
            }];
            
            [self hidHUD];
            [self showSuccess];
        
        }
        else{
            //error saving listing
            NSLog(@"error saving listing so hiding");
            [self hidHUD];
            NSLog(@"error saving %@", error);
            
            if (self.introMode == YES) {
                [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                [self.delegate dismissSimpleCreateVC:self];
            }
        }
    }];
}

-(void)findRelevantItems{
    [self.buyNowArray removeAllObjects];
    [self.buyNowIDs removeAllObjects];
    
    NSArray *WTBKeywords = [self.listing objectForKey:@"keywords"];
    
    PFQuery *salesQuery = [PFQuery queryWithClassName:@"forSaleItems"];
    [salesQuery whereKey:@"status" equalTo:@"live"];
    [salesQuery whereKey:@"keywords" containedIn:WTBKeywords];
    //    [salesQuery orderByDescending:@"createdAt"];
    salesQuery.limit = 10;
    [salesQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            [self.buyNowArray addObjectsFromArray:objects];
            
            NSLog(@"yo count %lu", objects.count);
            
            for (PFObject *forSale in objects) {
                [self.buyNowIDs addObject:forSale.objectId];
            }
            
            NSLog(@"count first time %lu", objects.count);
            
            if (objects.count < 10) {
                PFQuery *salesQuery2 = [PFQuery queryWithClassName:@"forSaleItems"];
                [salesQuery2 whereKey:@"status" equalTo:@"live"];
                [salesQuery2 orderByDescending:@"createdAt"];
                [salesQuery whereKey:@"objectId" notContainedIn:self.buyNowIDs];
                salesQuery2.limit = 10-self.buyNowArray.count; //CHANGE
                [salesQuery2 findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                    if (objects) {
                        NSLog(@"objects second time %lu", objects.count);
                        for (PFObject *forSale in objects) {
                            if (![self.buyNowIDs containsObject:forSale.objectId]) {
                                [self.buyNowArray addObject:forSale];
                                [self.buyNowIDs addObject:forSale.objectId];
                            }
                        }
                        NSLog(@"count second time %lu", self.buyNowArray.count);
                        [self.successView.collectionView reloadData];
                    }
                    else{
                        NSLog(@"error in second query %@", error);
                    }
                }];
            }
            else{
                [self.successView.collectionView reloadData];
            }
        }
        else{
            NSLog(@"error %@", error);
        }
    }];
}

-(void)showPushAlert{
    self.shownPushAlert = YES;
    self.searchBgView = [[UIView alloc]initWithFrame:[UIApplication sharedApplication].keyWindow.frame];
    self.searchBgView.alpha = 0.0;
    [self.searchBgView setBackgroundColor:[UIColor blackColor]];
    [[UIApplication sharedApplication].keyWindow addSubview:self.searchBgView];
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.searchBgView.alpha = 0.6f;
                     }
                     completion:nil];
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"customAlertView" owner:self options:nil];
    self.customAlert = (customAlertViewClass *)[nib objectAtIndex:0];
    self.customAlert.delegate = self;
    self.customAlert.titleLabel.text = @"Enable Push";
    self.customAlert.messageLabel.text = @"Tap to be notified when sellers/potential buyers send you a message on Bump";
    self.customAlert.numberOfButtons = 2;
    [self.customAlert.secondButton setTitle:@"E N A B L E" forState:UIControlStateNormal];
    
    if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
        //iphone5
        [self.customAlert setFrame:CGRectMake((self.view.frame.size.width/2)-125, -157, 250, 157)];
    }
    else{
        [self.customAlert setFrame:CGRectMake((self.view.frame.size.width/2)-150, -188, 300, 188)]; //iPhone 6/7 specific
    }
    
    self.customAlert.layer.cornerRadius = 10;
    self.customAlert.layer.masksToBounds = YES;
    
    [[UIApplication sharedApplication].keyWindow addSubview:self.customAlert];
    
    [UIView animateWithDuration:1.5
                          delay:0.2
         usingSpringWithDamping:0.5
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                                //iphone5
                                [self.customAlert setFrame:CGRectMake(0, 0, 250, 157)];
                            }
                            else{
                                [self.customAlert setFrame:CGRectMake(0, 0, 300, 188)]; //iPhone 6/7 specific
                            }
                            self.customAlert.center = self.view.center;
                            
                        }
                     completion:nil];
}

-(void)donePressed{
    [self.titleTextLabel becomeFirstResponder];
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.searchBgView.alpha = 0.0f;
                     }
                     completion:^(BOOL finished) {
                         self.searchBgView = nil;
                     }];
    
    [UIView animateWithDuration:1.0
                          delay:0.0
         usingSpringWithDamping:0.1
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            //Animations
                            if ([ [ UIScreen mainScreen ] bounds ].size.height == 568) {
                                //iphone5
                                [self.customAlert setFrame:CGRectMake((self.view.frame.size.width/2)-125, 1000, 250, 157)];
                            }
                            else{
                                [self.customAlert setFrame:CGRectMake((self.view.frame.size.width/2)-150, 1000, 300, 188)]; //iPhone 6/7 specific
                            }
                        }
                     completion:^(BOOL finished) {
                         //Completion Block
                         [self.customAlert setAlpha:0.0];
                         [self.customAlert removeFromSuperview];
                         self.customAlert = nil;
                     }];
}

-(void)firstPressed{
    [Answers logCustomEventWithName:@"Denied Push Permissions"
                   customAttributes:@{}];
    [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"declinedPushPermissions"];
    [self donePressed];
}

-(void)secondPressed{
    //present push dialog
    [Answers logCustomEventWithName:@"Accepted Push Permissions"
                   customAttributes:@{}];
    [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"askedForPushPermission"];
    UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                    UIUserNotificationTypeBadge |
                                                    UIUserNotificationTypeSound);
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                             categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    
    [self donePressed];
}

-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"Got it" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

-(void)toggleKeyboard{
    if (self.finishedListing == YES) {
        if ([self.titleTextLabel isFirstResponder]) {
            [self.titleTextLabel resignFirstResponder];
        }
        else{
            [self.titleTextLabel becomeFirstResponder];
        }
    }
}
- (IBAction)skipButtonPressed:(id)sender {
    [Answers logCustomEventWithName:@"Skipped intro create"
                   customAttributes:@{}];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
