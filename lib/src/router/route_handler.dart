library angular2.src.router.route_handler;

import "package:angular2/src/facade/lang.dart" show Type;
import "instruction.dart" show RouteData;

abstract class RouteHandler {
  Type componentType;
  Future<dynamic> resolveComponentType();
  RouteData data;
}
