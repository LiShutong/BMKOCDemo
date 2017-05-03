//
//  CACoordLayer.h
//

#import <BaiduMapAPI_Map/BMKMapComponent.h>
#import <BaiduMapAPI_Utils/BMKUtilsComponent.h>
#import "TracingPoint.h"
#import "MovingAnnotationView.h"

@interface CACoordLayer : CALayer

@property (nonatomic, assign) BMKMapView * mapView;

//定义一个BMKAnnotation对象
@property (nonatomic, strong) BMKPointAnnotation *annotation;
@property (nonatomic, strong) MovingAnnotationView *annotationView;

@property (nonatomic, strong) BMKPolyline *polyline;

@property (nonatomic) double mapx;

@property (nonatomic) double mapy;


@property (nonatomic) double transformRotation;

@property (nonatomic, strong)  layerMapPoint *layerMapPoint;

@property (nonatomic) CGPoint value;

@property (nonatomic) CGPoint centerOffset;

@end

