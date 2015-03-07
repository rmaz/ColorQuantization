//
//  ViewController.m
//  ImageQuantization
//
//  Created by Rnald on 05/03/2015.
//  Copyright (c) 2015 r-n-l-d. All rights reserved.
//

#import "ViewController.h"
#import "OBGradientView.h"
#import "ColorQuantizer.h"

@interface ViewController ()
@property (nonatomic, weak) IBOutlet OBGradientView *gradientView;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@end

@implementation ViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    ColorQuantizer *quantizer = [[ColorQuantizer alloc] init];
    NSArray *colors = [quantizer dominantColorsInImage:self.imageView.image];
    NSLog(@"colors: %@", colors);
    self.gradientView.colors = colors;
    self.gradientView.startPoint = CGPointMake(0, 0);
    self.gradientView.endPoint = CGPointMake(1, 1);
}

@end
