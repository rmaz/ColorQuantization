#import "ColorQuantizer.h"

#define MAX_COLORS 0x0fff

@implementation ColorQuantizer
{
    uint16_t _histogram[MAX_COLORS];
}

#pragma mark - Constants

static const uint16_t kMinPeakDistance = 50;

#pragma mark - Public

- (NSArray *)dominantColorsInImage:(UIImage *)image
{
    return [self referenceFunctionWithImage:image];
}

#pragma mark - Private

- (NSArray *)referenceFunctionWithImage:(UIImage *)image
{
    size_t bytesPerRow = CGImageGetBytesPerRow(image.CGImage);
    size_t bytesPerPixel = CGImageGetBitsPerPixel(image.CGImage) / 8;
    size_t width = CGImageGetWidth(image.CGImage);
    size_t height = CGImageGetHeight(image.CGImage);

    CGDataProviderRef dataProvider = CGImageGetDataProvider(image.CGImage);
    NSData *data = CFBridgingRelease(CGDataProviderCopyData(dataProvider));

    for (size_t h = 0; h < height; h++) {
        uint8_t *pixel = (uint8_t *)([data bytes] + h * bytesPerRow);

        for (size_t w = 0; w < width; w++) {
            const uint16_t mask = 0xf0;
            uint16_t r = pixel[0] & mask;
            uint16_t g = pixel[1] & mask;
            uint16_t b = pixel[2];
            uint16_t index =  (r << 4) + (g << 0) + (b >> 4);
            _histogram[index]++;

            pixel += bytesPerPixel;
        }
    }

    return [self dominantColorsInHistogram:_histogram length:MAX_COLORS];
}

- (NSArray *)dominantColorsInHistogram:(uint16_t *)histogram length:(uint16_t)length
{
    uint16_t maxInd = [self biggestIndexInHistogram:histogram range:NSMakeRange(0, length)];
    uint16_t leftInd = maxInd > kMinPeakDistance ? maxInd - kMinPeakDistance : 0;
    uint16_t rightInd = maxInd + kMinPeakDistance < length ? maxInd + kMinPeakDistance : length - 1;
    bzero(&histogram[leftInd], (rightInd - leftInd) * sizeof(histogram[0]));
    uint16_t secondMax = [self biggestIndexInHistogram:histogram range:NSMakeRange(0, length)];

    return @[ [self colorFromIndex:maxInd], [self colorFromIndex:secondMax] ];
}

- (uint16_t)biggestIndexInHistogram:(uint16_t *)histogram range:(NSRange)range
{
    uint16_t maxVal = 0;
    uint16_t maxInd = 0;
    for (uint16_t i = range.location; i < NSMaxRange(range); i++) {
        if (histogram[i] > maxVal) {
            maxVal = histogram[i];
            maxInd = i;
        }
    }
    return maxInd;
}

- (UIColor *)colorFromIndex:(uint16_t)index
{
    uint16_t b = (index & 0x0f) << 4;
    uint16_t g = (index & 0xf0) >> 0;
    uint16_t r = (index & 0xf00) >> 4;
    return [UIColor colorWithRed:r / 255.0 green:g / 255.0 blue:b / 255.0 alpha:1];
}

@end
