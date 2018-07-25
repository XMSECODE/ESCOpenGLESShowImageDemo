//
//  ViewController.m
//  ESCOpenGLESShowImageDemo
//
//  Created by xiang on 2018/7/25.
//  Copyright © 2018年 xiang. All rights reserved.
//

#import "ViewController.h"
#import "ESCOpenGLESView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ESCOpenGLESView *openglesView = (ESCOpenGLESView *)self.view;
    UIImage *image = [UIImage imageNamed:@"1"];
    [openglesView loadImage:image];
    
}


@end
