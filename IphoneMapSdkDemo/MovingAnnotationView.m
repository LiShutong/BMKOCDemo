//
//  MovingAnnotationView.m
//

#import "MovingAnnotationView.h"
#import "CACoordLayer.h"

#define TurnAnimationDuration 0.1

#define MapXAnimationKey @"mapx"
#define MapYAnimationKey @"mapy"
#define RotationAnimationKey @"transform.rotation.z"
#define MapAnimationKey @"value"

@interface MovingAnnotationView() {
    NSArray *_tracing;//轨迹点
}

@property (nonatomic, strong) NSMutableArray * animationList;

@end

@implementation MovingAnnotationView
{
    BMKMapPoint currDestination;
    BMKMapPoint lastDestination;
    layerMapPoint *lastDestinationPoint;
    BOOL isAnimatingX, isAnimatingY,isAnimatingRotation,isAnimation;
    NSInteger animateCompleteTimes;
}
@synthesize animateDelegate = _animateDelegate;
@synthesize imageView = _imageView;

#pragma mark - Animation
+ (Class)layerClass
{
    return [CACoordLayer class];
}

- (void)addTrackingAnimationForPoints:(NSArray *)points duration:(CFTimeInterval)duration
{
    _tracing = points;
    if (![points count])
    {
        return;
    }
    
    CACoordLayer * mylayer = ((CACoordLayer *)self.layer);
    
    //preparing
    NSUInteger num = 2*[points count] + 1;
    NSMutableArray *xvalues = [NSMutableArray arrayWithCapacity:num];
    NSMutableArray *yvalues = [NSMutableArray arrayWithCapacity:num];
    NSMutableArray *rotationValues = [NSMutableArray arrayWithCapacity:num];
    
    NSMutableArray *xyValues = [NSMutableArray arrayWithCapacity:num];
    NSMutableArray *Values = [NSMutableArray arrayWithCapacity:num];
    //BMKMapPoint *xyValue = malloc(([points count]) * sizeof(BMKMapPoint));
    
    NSMutableArray * times = [NSMutableArray arrayWithCapacity:num];
    
    
    double sumOfDistance = 0.f;
    double * dis = malloc(([points count]) * sizeof(double));
    
    //the first point is set by the destination of last animation.
    BMKMapPoint preLoc;
    if (!([self.animationList count] > 0 || isAnimatingX || isAnimatingY || isAnimation))
    {
        lastDestination = BMKMapPointMake(mylayer.mapx, mylayer.mapy);
        lastDestinationPoint = [[layerMapPoint alloc] init];
        lastDestinationPoint.mapx = mylayer.layerMapPoint.mapx;
        lastDestinationPoint.mapy = mylayer.layerMapPoint.mapy;
    }
    preLoc = lastDestination;
        
    [xvalues addObject:@(preLoc.x)];
    [yvalues addObject:@(preLoc.y)];
    [rotationValues addObject:@(0)];
    
    [xyValues addObject:lastDestinationPoint];
    
    [Values addObject:[NSValue valueWithCGPoint:CGPointMake(preLoc.x, preLoc.y)]];
    
    [times addObject:@(0.f)];
    
    //set the animation points.
    for (int i = 0; i<[points count]; i++)
    {
        TracingPoint * tp = points[i];
        
        //position
        BMKMapPoint p = BMKMapPointForCoordinate(tp.coordinate);
        layerMapPoint *layerPoint = [[layerMapPoint alloc]init];
        layerPoint.mapx= p.x;
        layerPoint.mapy = p.y;
        [xvalues addObjectsFromArray:@[@(p.x), @(p.x)]];//stop for turn
        [yvalues addObjectsFromArray:@[@(p.y), @(p.y)]];
        [rotationValues addObjectsFromArray:@[@(tp.angle),@(tp.angle)]];
        
        [xyValues addObject:layerPoint];
        [xyValues addObject:layerPoint];
        [Values addObject:[NSValue valueWithCGPoint:CGPointMake(p.x, p.y)]];
        [Values addObject:[NSValue valueWithCGPoint:CGPointMake(p.x, p.y)]];
        //distance
        dis[i] = BMKMetersBetweenMapPoints(p, preLoc);
        sumOfDistance = sumOfDistance + dis[i];
        dis[i] = sumOfDistance;
        
        //record pre
        preLoc = p;
    }
    
    //set the animation times.
    double preTime = 0.f;
    double turnDuration = TurnAnimationDuration/duration;
    for (int i = 0; i<[points count]; i++)
    {
        double turnEnd = dis[i]/sumOfDistance;
        double turnStart = (preTime > turnEnd - turnDuration) ? (turnEnd + preTime) * 0.5 : turnEnd - turnDuration;
        
        [times addObjectsFromArray:@[@(turnStart), @(turnEnd)]];

        preTime = turnEnd;
    }
    
    //record the destination.
    TracingPoint * last = [points lastObject];
    lastDestination = BMKMapPointForCoordinate(last.coordinate);

    free(dis);
    
    
    
    // add animation.
    CAKeyframeAnimation *xanimation = [CAKeyframeAnimation animationWithKeyPath:MapXAnimationKey];
    xanimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    xanimation.calculationMode = kCAAnimationLinear;
    xanimation.values   = xvalues;
    xanimation.keyTimes = times;
    xanimation.duration = duration;
    xanimation.delegate = self;
    xanimation.fillMode = kCAFillModeForwards;
    
    CAKeyframeAnimation *yanimation = [CAKeyframeAnimation animationWithKeyPath:MapYAnimationKey];
    yanimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    xanimation.calculationMode = kCAAnimationLinear;
    yanimation.values   = yvalues;
    yanimation.keyTimes = times;
    yanimation.duration = duration;
    yanimation.delegate = self;
    yanimation.fillMode = kCAFillModeForwards;
    
    CAKeyframeAnimation *tranfAnimation = [CAKeyframeAnimation animationWithKeyPath:RotationAnimationKey];
    tranfAnimation.values = rotationValues;
    tranfAnimation.keyTimes = times;
    tranfAnimation.duration = duration;
    tranfAnimation.delegate = self;
    tranfAnimation.fillMode = kCAFillModeForwards;
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:MapAnimationKey];
    animation.values = Values;
    animation.keyTimes = times;
    animation.duration = duration;
    animation.delegate = self;
    animation.fillMode = kCAFillModeForwards;
    
    //[self pushBackAnimation:tranfAnimation];
    [self pushBackAnimation:xanimation];
    [self pushBackAnimation:yanimation];
    //[self pushBackAnimation:animation];
    
    
    mylayer.mapView = [self mapView];
}

- (void)pushBackAnimation:(CAPropertyAnimation *)anim
{
    [self.animationList addObject:anim];

    if ([self.layer animationForKey:anim.keyPath] == nil)
    {
        [self popFrontAnimationForKey:anim.keyPath];
    }
}

- (void)popFrontAnimationForKey:(NSString *)key
{
    [self.animationList enumerateObjectsUsingBlock:^(CAKeyframeAnimation * obj, NSUInteger idx, BOOL *stop)
     {
         if ([obj.keyPath isEqualToString:key])
         {
             [self.layer addAnimation:obj forKey:obj.keyPath];
             [self.animationList removeObject:obj];

             if ([key isEqualToString:MapXAnimationKey])
             {
                 isAnimatingX = YES;
             }
             else if([key isEqualToString:MapYAnimationKey])
             {
                 isAnimatingY = YES;
             }
             else if([key isEqualToString:RotationAnimationKey])
             {
                 isAnimatingRotation = YES;
             }
             else if([key isEqualToString:MapAnimationKey])
             {
                 isAnimation = YES;
             }
             *stop = YES;
         }
     }];
}

#pragma mark - Animation Delegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if ([anim isKindOfClass:[CAKeyframeAnimation class]])
    {
        CAKeyframeAnimation * keyAnim = ((CAKeyframeAnimation *)anim);
        if ([keyAnim.keyPath isEqualToString:MapXAnimationKey])
        {
            isAnimatingX = NO;

            CACoordLayer * mylayer = ((CACoordLayer *)self.layer);
            mylayer.mapx = ((NSNumber *)[keyAnim.values lastObject]).doubleValue;
            currDestination.x = mylayer.mapx;
            
            [self updateAnnotationCoordinate];

            [self popFrontAnimationForKey:MapXAnimationKey];
        }
        else if ([keyAnim.keyPath isEqualToString:MapYAnimationKey])
        {
            isAnimatingY = NO;

            CACoordLayer * mylayer = ((CACoordLayer *)self.layer);
            mylayer.mapy = ((NSNumber *)[keyAnim.values lastObject]).doubleValue;
            currDestination.y = mylayer.mapy;
            [self updateAnnotationCoordinate];

            [self popFrontAnimationForKey:MapYAnimationKey];
        }
        else if ([keyAnim.keyPath isEqualToString:MapAnimationKey])
        {
            isAnimation = NO;
            
            CACoordLayer * mylayer = ((CACoordLayer *)self.layer);
            NSValue *value = [keyAnim.values lastObject];
            mylayer.value = [value CGPointValue];
            
//            currDestination.x = mylayer.layerMapPoint.mapx;
//            currDestination.y = mylayer.layerMapPoint.mapy;
            [self updateAnnotationCoordinate];
            [self popFrontAnimationForKey:MapAnimationKey];
        }

        animateCompleteTimes++;
        if (animateCompleteTimes % 2 == 0) {
            if (_animateDelegate && [_animateDelegate respondsToSelector:@selector(movingAnnotationViewAnimationFinished)]) {
                [_animateDelegate movingAnnotationViewAnimationFinished];
            }
        }
    }
}


- (void)updateAnnotationCoordinate
{
    if (! (isAnimatingX || isAnimatingY || isAnimation) )
    {
        self.annotation.coordinate = BMKCoordinateForMapPoint(currDestination);
    }
}

#pragma mark - Property

- (NSMutableArray *)animationList
{
    if (_animationList == nil)
    {
        _animationList = [NSMutableArray array];
    }
    return _animationList;
}

- (BMKMapView *)mapView
{
    return (BMKMapView*)(self.superview.superview.superview);
}

#pragma mark - Override

- (void)setCenterOffset:(CGPoint)centerOffset
{
    CACoordLayer * mylayer = ((CACoordLayer *)self.layer);
    mylayer.centerOffset = centerOffset;
    [super setCenterOffset:centerOffset];
}

#pragma mark - Life Cycle

- (id)initWithAnnotation:(id<BMKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self)
    {
        [self setBounds:CGRectMake(0.f, 0.f, 22.f, 22.f)];
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.f, 0.f, 22.f, 22.f)];
        _imageView.image = [UIImage imageNamed:@"sportarrow.png"];
        [self addSubview:_imageView];
        //self.image = _imageView.image;
        //self.imageView.transform = CGAffineTransformMakeRotation(rand() % 360 - 180);
        
        CACoordLayer * mylayer = ((CACoordLayer *)self.layer);
        BMKMapPoint mapPoint = BMKMapPointForCoordinate(annotation.coordinate);
        mylayer.mapx = mapPoint.x;
        mylayer.mapy = mapPoint.y;
        
        layerMapPoint *mylayerPoint = [[layerMapPoint alloc] init];
        mylayerPoint.mapx = mapPoint.x;
        mylayerPoint.mapy = mapPoint.y;
        mylayer.layerMapPoint = mylayerPoint;
        
        mylayer.value = CGPointMake(mapPoint.x, mapPoint.y);

        //初始化CACoordLayer定义的BMKAnnotation对象
        mylayer.annotation = self.annotation;

        mylayer.centerOffset = self.centerOffset;
        
        mylayer.annotationView = self;
        
        isAnimatingX = NO;
        isAnimatingY = NO;
        isAnimation = NO;
    }
    return self;
}


@end
