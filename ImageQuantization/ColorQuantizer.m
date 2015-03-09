#import "ColorQuantizer.h"
#import <ImageIO/ImageIO.h>

@implementation ColorQuantizer
{
    uint16_t *_histogram;
}

#pragma mark - Constants

static const uint16_t kMaxColors = 0x1000;
static const int kMinPeakDistance = 200;
static const int kMinEdgeDistance = 80;
static const CGSize kImageSize = { 256, 256 };

#define UNPACK_RED(index) ((index & 0x0f00) >> 4)
#define UNPACK_GREEN(index) (index & 0x00f0)
#define UNPACK_BLUE(index)  ((index & 0x000f) << 4)

#pragma mark - Init

- (id)init
{
    self = [super init];
    if (self) {
        _histogram = malloc(kMaxColors * sizeof(uint16_t));
    }
    return self;
}

- (void)dealloc
{
    free(_histogram);
}

#pragma mark - Public

- (NSArray *)dominantColorsInImage:(UIImage *)image
{
    CFAbsoluteTime t1 = CFAbsoluteTimeGetCurrent();
    NSData *imageData = [self scaledImageDataFromImage:image size:kImageSize];
    CFAbsoluteTime t2 = CFAbsoluteTimeGetCurrent();
    NSLog(@"resampling time %.0f ms", 1000*(t2 - t1));

    t1 = CFAbsoluteTimeGetCurrent();
    [self calculateHistogramWithImageData:imageData];
    t2 = CFAbsoluteTimeGetCurrent();
    NSLog(@"histogram calculation took %.3f ms\n", 1000*(t2-t1));

    t1 = CFAbsoluteTimeGetCurrent();
    NSArray *colors = [self dominantColorsInHistogram:_histogram length:kMaxColors];
    t2 = CFAbsoluteTimeGetCurrent();
    NSLog(@"peak detection took %.3f ms", 1000*(t2-t1));

    return colors;
}

#pragma mark - Private

- (NSData *)scaledImageDataFromImage:(UIImage *)image size:(CGSize)size
{
    NSUInteger length = sizeof(uint16_t) * size.width * size.height;
    void *data = malloc(length);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(data, size.width, size.height, 5, size.width * sizeof(uint16_t), colorSpace,
                                             kCGBitmapByteOrder16Little | kCGImageAlphaNoneSkipFirst);
    CGContextDrawImage(ctx, CGRectMake(0, 0, size.width, size.height), image.CGImage);
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);

    return [[NSData alloc] initWithBytesNoCopy:data length:length];
}

- (void)calculateHistogramWithImageData:(NSData *)imageData
{
    bzero(_histogram, kMaxColors * sizeof(_histogram[0]));

    NSUInteger *pixel = (NSUInteger *)imageData.bytes;
    for (size_t i = 0; i < [imageData length]; i += sizeof(NSUInteger)) {

        for (int p = 0; p < sizeof(NSUInteger) / sizeof(uint16_t); p++) {
            NSUInteger value = *pixel >> (p * 16);
            uint16_t index = ((value & 0x7800) >> 3) | ((value & 0x3c0) >> 2) | ((value & 0x1e) >> 1);
            _histogram[index]++;
        }
        pixel++;
    }
}

- (NSArray *)dominantColorsInHistogram:(uint16_t *)histogram length:(uint16_t)length
{
    uint16_t maxInd = [self biggestIndexInHistogram:histogram length:length];
    uint16_t secondInd = [self biggestIndexInHistogram:histogram length:length distantFromColor:maxInd];

    return @[ [self colorFromIndex:maxInd], [self colorFromIndex:secondInd] ];
}

- (uint16_t)biggestIndexInHistogram:(uint16_t *)histogram length:(uint16_t)length
{
    uint16_t maxVal = 0;
    uint16_t maxInd = 0;
    for (uint16_t i = 0; i < length; i++) {
        if (histogram[i] > maxVal &&
            [self distanceFromBlack:i] > kMinEdgeDistance &&
            [self distanceFromWhite:i] > kMinEdgeDistance) {
            maxVal = histogram[i];
            maxInd = i;
        }
    }
    return maxInd;
}

- (uint16_t)biggestIndexInHistogram:(uint16_t *)histogram length:(uint16_t)length distantFromColor:(uint16_t)color
{
    uint16_t maxVal = 0;
    uint16_t maxInd = 0;
    for (uint16_t i = 0; i < length; i++) {
        if (histogram[i] > maxVal &&
            [self distanceFromBlack:i] > kMinEdgeDistance &&
            [self distanceFromWhite:i] > kMinEdgeDistance &&
            [self distanceFromColor:i toColor:color] > kMinPeakDistance) {
            maxVal = histogram[i];
            maxInd = i;
        }
    }
    return maxInd;
}

- (UIColor *)colorFromIndex:(uint16_t)index
{
    return [UIColor colorWithRed:UNPACK_RED(index) / 255.0 green:UNPACK_GREEN(index) / 255.0 blue:UNPACK_BLUE(index) / 255.0 alpha:1];
}

- (int)distanceFromBlack:(uint16_t)index
{
    return UNPACK_RED(index) + UNPACK_GREEN(index) + UNPACK_BLUE(index);
}

- (int)distanceFromWhite:(uint16_t)index
{
    return 255 - UNPACK_RED(index) + 255 - UNPACK_GREEN(index) + 255 - UNPACK_BLUE(index);
}

- (int)distanceFromColor:(uint16_t)color1 toColor:(uint16_t)color2
{
    return abs((int)UNPACK_RED(color1)   - UNPACK_RED(color2)) +
           abs((int)UNPACK_GREEN(color1) - UNPACK_GREEN(color2)) +
           abs((int)UNPACK_BLUE(color1)  - UNPACK_BLUE(color2));
}

@end
