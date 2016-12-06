//
//  ListingCompleteView.m
//  
//
//  Created by Jack Ryder on 27/02/2016.
//
//

#import "ListingCompleteView.h"
#import "FBGroupShareViewController.h"

@interface ListingCompleteView ()

@end

@implementation ListingCompleteView

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"D O N E";
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Regular" size:13],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    self.mainText.adjustsFontSizeToFitWidth = YES;
    self.mainText.minimumScaleFactor=0.5;
    
    self.navigationItem.hidesBackButton = YES;
    self.mainCell.selectionStyle = UITableViewCellSelectionStyleNone;
    self.cellButtonOne.selectionStyle = UITableViewCellSelectionStyleNone;
    self.cellButtonTwo.selectionStyle = UITableViewCellSelectionStyleNone;
    self.cellButtonThree.selectionStyle = UITableViewCellSelectionStyleNone;
    self.cellButtonFour.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.shareMode = NO;
    self.anotherPressed = NO;
    self.resetOnDisappear = YES;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    NSLog(@"setting to yes");
    self.resetOnDisappear = YES;
}

-(void)viewDidDisappear:(BOOL)animated{
    
    //reset the share mode so doesn't dismiss VC
    if (self.shareMode == YES) {
        self.shareMode = NO;
    }
    else{
        //need to reset if change tabs but not if click edit
        NSLog(self.resetOnDisappear ? @"Yes" : @"No");
        if (self.resetOnDisappear == YES) {
            [self.delegate listingEdit:self didFinishEnteringItem:@"new"];
        }
        
        [self.navigationController popViewControllerAnimated:NO];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return 5;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
        if (indexPath.row == 0) {
            return self.mainCell;
        }
        else if(indexPath.row == 1){
            return self.cellButtonOne;
        }
        else if(indexPath.row == 2){
            return self.cellButtonTwo;
        }
        else if(indexPath.row == 3){
            return self.cellButtonThree;
        }
        else if(indexPath.row == 4){
            return self.cellButtonFour;
        }

    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            return 295;
        }
        else if(indexPath.row == 1){
            return 51;
        }
        else if(indexPath.row == 2){
            return 51;
        }
        else if(indexPath.row == 3){
            return 51;
        }
        else if(indexPath.row == 4){
            return 51;
        }
    }
    return 44;
}

- (IBAction)sharePressed:(id)sender {
    NSMutableArray *items = [NSMutableArray new];
    self.resetOnDisappear = NO;
    [items addObject:@"I just listed a WTB on Bump! Know anyone that can sell it to me? Download now: http://apple.co/2aY3rBk"];
    UIActivityViewController *activityController = [[UIActivityViewController alloc]initWithActivityItems:items applicationActivities:nil];
    [self presentViewController:activityController animated:YES completion:nil];
}
- (IBAction)shareToGroupPresse:(id)sender {
    self.shareMode = YES;
    FBGroupShareViewController *vc = [[FBGroupShareViewController alloc]init];
    vc.objectId = self.lastObjectId;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:navigationController animated:YES completion:nil];
}
- (IBAction)createAnotherPressed:(id)sender {
    self.anotherPressed = YES;
    [self.delegate listingEdit:self didFinishEnteringItem:@"new"];
    self.resetOnDisappear = NO;
    [self.navigationController popViewControllerAnimated:YES];
}
- (IBAction)editListingPressed:(id)sender {
    [self.delegate lastId:self didFinishEnteringItem:self.lastObjectId];
    [self.delegate listingEdit:self didFinishEnteringItem:@"edit"];
    self.resetOnDisappear = NO;
    [self.navigationController popViewControllerAnimated:YES];
}
-(void)resetNavStack{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
