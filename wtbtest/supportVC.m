//
//  supportVC.m
//  wtbtest
//
//  Created by Jack Ryder on 10/03/2018.
//  Copyright © 2018 Jack Ryder. All rights reserved.
//

#import "supportVC.h"
#import <Crashlytics/Crashlytics.h>
#import "Mixpanel/Mixpanel.h"
#import "supportAnswerVC.h"
#import <SafariServices/SafariServices.h>

@interface supportVC ()

@end

@implementation supportVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    
    self.resultArray = [NSArray array];
    
    self.title = @"S U P P O R T";
    
    [Answers logCustomEventWithName:@"Viewed page"
                   customAttributes:@{
                                      @"pageName":@"Following"
                                      }];
    
    PFQuery *topicsQuery = [PFQuery queryWithClassName:@"SupportObjects"];
    [topicsQuery whereKey:@"status" equalTo:@"live"];
    [topicsQuery orderByAscending:@"order"];

    if (self.tier1Mode) {
        [topicsQuery whereKey:@"tier" equalTo:@1];
    }
    else{
        [topicsQuery whereKey:@"tier" equalTo:@2];
        
        //access passed supportObject and retrieve it's children
        NSString *topic = [self.supportObject objectForKey:@"topic"];
        [topicsQuery whereKey:@"parentTopic" equalTo:topic];
    }
    
    [self showHUD];
    [topicsQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (objects) {
            [self hideHUD];
            
            self.resultArray = objects;
            [self.tableView reloadData];
        }
        else{
            [self hideHUD];
            [self showAlertWithTitle:@"Error Retrieving Support Topics" andMsg:@"Ensure you're connected to the internet and then try again.\n\nIf the problem persists please email hello@sobump.com"];
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"PingFangSC-Medium" size:12],
                                    NSFontAttributeName, nil];
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;
    
    [self.navigationController.navigationBar setHidden:NO];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.resultArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    //setup cell
    [cell.textLabel setFont:[UIFont fontWithName:@"PingFangSC-Regular" size:15]];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    PFObject *supportObj = [self.resultArray objectAtIndex:indexPath.row];
    NSString *title = [supportObj objectForKey:@"title"];
    cell.textLabel.text = title;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    PFObject *supportObj = [self.resultArray objectAtIndex:indexPath.row];

    NSString *subTopicsExist = [supportObj objectForKey:@"subTopics"];
    NSString *topic = [supportObj objectForKey:@"topic"];

    if ([subTopicsExist isEqualToString:@"YES"]) {
        supportVC *vc = [[supportVC alloc]init];
        vc.tier1Mode = NO;
        vc.supportObject = supportObj;
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if ([topic isEqualToString:@"general"]){
        //present FAQs
        NSString *URLString = @"https://help.sobump.com/";
        SFSafariViewController *safariView = [[SFSafariViewController alloc]initWithURL:[NSURL URLWithString:URLString]];
        if (@available(iOS 11.0, *)) {
            safariView.dismissButtonStyle = UIBarButtonSystemItemCancel;
        }
        
        if (@available(iOS 10.0, *)) {
            safariView.preferredControlTintColor = [UIColor colorWithRed:0.29 green:0.29 blue:0.29 alpha:1];
        }
        
        [self.navigationController presentViewController:safariView animated:YES completion:nil];
    }
    else{
        //go straight to answer VC and pass this support object
        supportAnswerVC *vc = [[supportAnswerVC alloc]init];
        vc.supportObject = supportObj;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 70;
}

-(void)showHUD{
    
    if (!self.spinner) {
        self.spinner = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleArc];
    }
    
    [self.spinner startAnimating];
    
    if (!self.hud) {
        self.hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        self.hud.square = YES;
        self.hud.mode = MBProgressHUDModeCustomView;
        self.hud.customView = self.spinner;
    }
    
}

-(void)hideHUD{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow animated:YES];
    });
    
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.hud.labelText = @"";
        self.hud = nil;
    });
}

-(void)showAlertWithTitle:(NSString *)title andMsg:(NSString *)msg{
    
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertView addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [self presentViewController:alertView animated:YES completion:nil];
}

                               
@end
