#import "ColorQuantizer.h"

@implementation ColorQuantizer
{
    uint16_t *_histogram;
}

#pragma mark - Constants

static const uint16_t kMaxColors = 0x1000;
static const uint16_t kMinPeakDistance = 100;
static const CGSize kImageSize = { 256, 256 };

#define PACK_PIXEL(bytePtr) ( ((uint16_t)(bytePtr[2] & 0xf0) << 4) + (bytePtr[1] & 0xf0) + (bytePtr[0] >> 4) )
#define UNPACK_RED(index)   ((index & 0xf00) >> 4)
#define UNPACK_GREEN(index) (index & 0xf0)
#define UNPACK_BLUE(index)  ((index & 0x0f) << 4)

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
    bzero(_histogram, kMaxColors * sizeof(_histogram[0]));

    for (size_t h = 0; h < height; h++) {
        uint8_t *pixel = (uint8_t *)([imageData bytes] + h * bytesPerRow);

        for (size_t w = 0; w < width; w++) {
            _histogram[PACK_PIXEL(pixel)]++;
            pixel += 4;
        }
    }

    return [self dominantColorsInHistogram:_histogram length:kMaxColors];
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
    return [UIColor colorWithRed:UNPACK_RED(index) / 255.0 green:UNPACK_GREEN(index) / 255.0 blue:UNPACK_BLUE(index) / 255.0 alpha:1];
}

@end
