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

@property(nonatomic,weak)ESCOpenGLESView* openGLESView;

@property(nonatomic,weak)UIImageView* imageView;

@property(nonatomic,assign)NSInteger currentImageIndex;

@property(nonatomic,strong)dispatch_queue_t testqueue;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.testqueue = dispatch_queue_create("test", 0);
    
    CGFloat screenwidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenheight = [UIScreen mainScreen].bounds.size.height;
    
    CGFloat width = screenwidth;
    CGFloat height = screenheight;
    
    ESCOpenGLESView *openGLESView = [[ESCOpenGLESView alloc] initWithFrame:CGRectMake(0, 0, width, height / 2)];
    [self.view addSubview:openGLESView];
    self.openGLESView = openGLESView;
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, screenheight / 2, screenwidth, screenheight / 2)];
    [self.view addSubview:imageView];
    self.imageView = imageView;
    
    [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(loadImages) userInfo:nil repeats:YES];
}

- (void)loadImages {
    self.currentImageIndex++;
    if (self.currentImageIndex > 3) {
        self.currentImageIndex = 1;
    }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self loadImageWithName:[NSString stringWithFormat:@"%ld",(long)self.currentImageIndex]];
    });
}

- (void)loadImageWithName:(NSString *)imageName {
    UIImage *image = [UIImage imageNamed:imageName];
    [self.openGLESView loadImage:image];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.imageView.image = image;
    });

}


@end
