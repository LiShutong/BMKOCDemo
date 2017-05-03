//
//  CACoordLayer.m
//

#import "CACoordLayer.h"
#import "SportPathDemoViewController.h"

static double mapTempy = 0;
static double mapTempx = 0;
static size_t retryNum = 0;
CLLocationCoordinate2D paths[1000];
@implementation CACoordLayer

@dynamic mapx;
@dynamic mapy;
@dynamic value;



- (id)initWithLayer:(id)layer
{
    if ((self = [super initWithLayer:layer]))
    {
        if ([layer isKindOfClass:[CACoordLayer class]])
        {
            CACoordLayer * input = layer;
            self.mapx = input.mapx;
            self.mapy = input.mapy;
            self.value = input.value;
            //NSLog(@"self.value :%f,%f",self.value.x,self.value.y);
            [self setNeedsDisplay];
        }
    }
    return self;
}

+ (BOOL)needsDisplayForKey:(NSString *)key
{
    if ([@"mapx" isEqualToString:key])
    {
        return YES;
    }
    if ([@"mapy" isEqualToString:key])
    {
        return YES;
    }
    if ([@"value" isEqualToString:key])
    {
        return YES;
    }
    
    return [super needsDisplayForKey:key];
}

- (void)display
{
    CACoordLayer * layer = [self presentationLayer];
    
//    if (mapTempy != layer.mapx || retryNum >= 5) {
    
    BMKMapPoint mappoint;
    mappoint = BMKMapPointMake(layer.mapx, layer.mapy);
    NSLog(@"一layerPoint : %f,%f", mappoint.x,mappoint.y);
//    NSLog(@"D-value:%f,%f", mappoint.x - mapTempx,mappoint.y - mapTempy);
    
    //mappoint = BMKMapPointMake(layer.layerMapPoint.mapx, layer.layerMapPoint.mapy);
    //NSLog(@"二layerPoint : %f,%f", mappoint.x,mappoint.y);
    
    //根据得到的坐标值，将其设置为annotation的经纬度
    self.annotation.coordinate = BMKCoordinateForMapPoint(mappoint);
    //[self.mapView setCenterCoordinate:self.annotation.coordinate animated:YES];
    //paths[retryNum] = BMKCoordinateForMapPoint(mappoint);
    //设置layer的位置，显示动画
    CGPoint center = [self.mapView convertCoordinate:BMKCoordinateForMapPoint(mappoint) toPointToView:self.mapView];
    self.position = center;
    
//    mapTempx = layer.mapx;
//    mapTempy = layer.mapy;
//    retryNum = 0;
//    
//    } else {
//        retryNum ++;
//    }
}

@end


