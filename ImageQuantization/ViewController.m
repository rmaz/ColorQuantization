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
@property (nonatomic) IBOutlet ColorQuantizer *quantizer;
@property (nonatomic) NSArray *images;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.images = @[
                    [UIImage imageNamed:@"sky"],
                    [UIImage imageNamed:@"babboon"],
                    [UIImage imageNamed:@"rose"],
                    [UIImage imageNamed:@"purple"]
                    ];
    [self pickImageWithIndex:0];
}

- (IBAction)imageButtonTapped:(id)sender
{
    NSUInteger currentIndex = [self.images indexOfObjectIdenticalTo:self.imageView.image];
    [self pickImageWithIndex:(currentIndex + 1) % self.images.count];
}

- (void)pickImageWithIndex:(NSUInteger)index
{
    UIImage *image = self.images[index];
    NSArray *colors = [self.quantizer dominantColorsInImage:image];

    NSLog(@"colors: %@", colors);
    self.gradientView.colors = colors;
    self.gradientView.startPoint = CGPointMake(0, 0);
    self.gradientView.endPoint = CGPointMake(1, 1);
    self.imageView.image = image;
}

@end
