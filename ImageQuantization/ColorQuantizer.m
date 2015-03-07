#import "ColorQuantizer.h"

#define MAX_COLORS 0x1000

@implementation ColorQuantizer
{
    uint16_t _histogram[MAX_COLORS];
}

#pragma mark - Constants

static const uint16_t kMinPeakDistance = 100;
static const CGSize kImageSize = { 256, 256 };

#pragma mark - Public

- (NSArray *)dominantColorsInImage:(UIImage *)image
{
    bzero(_histogram, MAX_COLORS * sizeof(_histogram[0]));

    UIImage *resampledImage = [self resizedImageFromImage:image];
    size_t bytesPerRow = CGImageGetBytesPerRow(resampledImage.CGImage);
    size_t width = CGImageGetWidth(resampledImage.CGImage);
    size_t height = CGImageGetHeight(resampledImage.CGImage);
    CGDataProviderRef dataProvider = CGImageGetDataProvider(resampledImage.CGImage);

    // image data will be in BGRA
    NSData *data = CFBridgingRelease(CGDataProviderCopyData(dataProvider));

    return [self referenceFunctionWithData:data width:width height:height bytesPerRow:bytesPerRow];
}

#pragma mark - Private

- (UIImage *)resizedImageFromImage:(UIImage *)image
{
    UIGraphicsBeginImageContextWithOptions(kImageSize, YES, 1);
    [image drawInRect:CGRectMake(0, 0, kImageSize.width, kImageSize.height)];
    UIImage *resampledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return resampledImage;
}

- (NSArray *)referenceFunctionWithData:(NSData *)imageData width:(size_t)width height:(size_t)height bytesPerRow:(size_t)bytesPerRow
{
    for (size_t h = 0; h < height; h++) {
        uint8_t *pixel = (uint8_t *)([imageData bytes] + h * bytesPerRow);

        for (size_t w = 0; w < width; w++) {
            const uint16_t mask = 0xf0;
            uint16_t b = pixel[0];
            uint16_t g = pixel[1] & mask;
            uint16_t r = pixel[2] & mask;
            uint16_t index =  (r << 4) + (g << 0) + (b >> 4);
            _histogram[index]++;

            pixel += 4;
        }
    }

    return [self dominantColorsInHistogram:_histogram length:MAX_COLORS];
}

- (NSArray *)dominantColorsInHistogram:(uint16_t *)histogram length:(uint16_t)length
{
    NSRange range = NSMakeRange(0, length);
    uint16_t maxInd = [self biggestIndexInHistogram:histogram range:range];
    uint16_t leftInd = maxInd > kMinPeakDistance ? maxInd - kMinPeakDistance : 0;
    uint16_t rightInd = maxInd + kMinPeakDistance < length ? maxInd + kMinPeakDistance : length - 1;
    bzero(&histogram[leftInd], (rightInd - leftInd) * sizeof(histogram[0]));
    uint16_t secondMax = [self biggestIndexInHistogram:histogram range:range];

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
