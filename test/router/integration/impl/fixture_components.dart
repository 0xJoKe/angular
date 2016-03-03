library angular2.test.router.integration.impl.fixture_components;

import "dart:async";
import "package:angular2/core.dart" show Component;
import "package:angular2/router.dart"
    show
        AsyncRoute,
        Route,
        Redirect,
        RouteConfig,
        RouteParams,
        RouteData,
        ROUTER_DIRECTIVES;
import "package:angular2/src/facade/async.dart" show PromiseWrapper;
import "package:angular2/src/facade/lang.dart" show isPresent;
import "package:angular2/src/core/linker/dynamic_component_loader.dart"
    show DynamicComponentLoader, ComponentRef;
import "package:angular2/src/core/linker/element_ref.dart" show ElementRef;

@Component(selector: "goodbye-cmp", template: '''{{farewell}}''')
class GoodbyeCmp {
  String farewell;
  GoodbyeCmp() {
    this.farewell = "goodbye";
  }
}

@Component(selector: "hello-cmp", template: '''{{greeting}}''')
class HelloCmp {
  String greeting;
  HelloCmp() {
    this.greeting = "hello";
  }
}

helloCmpLoader() {
  return PromiseWrapper.resolve(HelloCmp);
}

@Component(selector: "user-cmp", template: '''hello {{user}}''')
class UserCmp {
  String user;
  UserCmp(RouteParams params) {
    this.user = params.get("name");
  }
}

userCmpLoader() {
  return PromiseWrapper.resolve(UserCmp);
}

@Component(
    selector: "parent-cmp",
    template: '''inner { <router-outlet></router-outlet> }''',
    directives: const [ROUTER_DIRECTIVES])
@RouteConfig(
    const [const Route(path: "/b", component: HelloCmp, name: "Child")])
class ParentCmp {}

parentCmpLoader() {
  return PromiseWrapper.resolve(ParentCmp);
}

@Component(
    selector: "parent-cmp",
    template: '''inner { <router-outlet></router-outlet> }''',
    directives: const [ROUTER_DIRECTIVES])
@RouteConfig(
    const [const AsyncRoute(path: "/b", loader: helloCmpLoader, name: "Child")])
class AsyncParentCmp {}

asyncParentCmpLoader() {
  return PromiseWrapper.resolve(AsyncParentCmp);
}

@Component(
    selector: "parent-cmp",
    template: '''inner { <router-outlet></router-outlet> }''',
    directives: const [ROUTER_DIRECTIVES])
@RouteConfig(const [
  const AsyncRoute(
      path: "/b", loader: helloCmpLoader, name: "Child", useAsDefault: true)
])
class AsyncDefaultParentCmp {}

asyncDefaultParentCmpLoader() {
  return PromiseWrapper.resolve(AsyncDefaultParentCmp);
}

@Component(
    selector: "parent-cmp",
    template: '''inner { <router-outlet></router-outlet> }''',
    directives: const [ROUTER_DIRECTIVES])
@RouteConfig(const [
  const Route(
      path: "/b", component: HelloCmp, name: "Child", useAsDefault: true)
])
class ParentWithDefaultCmp {}

parentWithDefaultCmpLoader() {
  return PromiseWrapper.resolve(ParentWithDefaultCmp);
}

@Component(
    selector: "team-cmp",
    template: '''team {{id}} | user { <router-outlet></router-outlet> }''',
    directives: const [ROUTER_DIRECTIVES])
@RouteConfig(
    const [const Route(path: "/user/:name", component: UserCmp, name: "User")])
class TeamCmp {
  String id;
  TeamCmp(RouteParams params) {
    this.id = params.get("id");
  }
}

@Component(
    selector: "team-cmp",
    template: '''team {{id}} | user { <router-outlet></router-outlet> }''',
    directives: const [ROUTER_DIRECTIVES])
@RouteConfig(const [
  const AsyncRoute(path: "/user/:name", loader: userCmpLoader, name: "User")
])
class AsyncTeamCmp {
  String id;
  AsyncTeamCmp(RouteParams params) {
    this.id = params.get("id");
  }
}

asyncTeamLoader() {
  return PromiseWrapper.resolve(AsyncTeamCmp);
}

@Component(selector: "data-cmp", template: '''{{myData}}''')
class RouteDataCmp {
  bool myData;
  RouteDataCmp(RouteData data) {
    this.myData = data.get("isAdmin");
  }
}

asyncRouteDataCmp() {
  return PromiseWrapper.resolve(RouteDataCmp);
}

@Component(selector: "redirect-to-parent-cmp", template: "redirect-to-parent")
@RouteConfig(const [
  const Redirect(path: "/child-redirect", redirectTo: const ["../HelloSib"])
])
class RedirectToParentCmp {}

@Component(
    selector: "dynamic-loader-cmp", template: '''{ <div #viewport></div> }''')
@RouteConfig(const [const Route(path: "/", component: HelloCmp)])
class DynamicLoaderCmp {
  DynamicComponentLoader _dynamicComponentLoader;
  ElementRef _elementRef;
  ComponentRef _componentRef = null;
  DynamicLoaderCmp(this._dynamicComponentLoader, this._elementRef) {}
  Future<dynamic> onSomeAction() {
    if (isPresent(this._componentRef)) {
      this._componentRef.dispose();
      this._componentRef = null;
    }
    return this
        ._dynamicComponentLoader
        .loadIntoLocation(
            DynamicallyLoadedComponent, this._elementRef, "viewport")
        .then((cmp) {
      this._componentRef = cmp;
    });
  }
}

@Component(
    selector: "loaded-cmp",
    template: "<router-outlet></router-outlet>",
    directives: const [ROUTER_DIRECTIVES])
class DynamicallyLoadedComponent {}
