library angular2.test.router.router_spec;

import "dart:async";
import "package:angular2/testing_internal.dart"
    show
        AsyncTestCompleter,
        describe,
        proxy,
        it,
        iit,
        xit,
        ddescribe,
        expect,
        inject,
        beforeEach,
        beforeEachProviders;
import "spies.dart" show SpyRouterOutlet;
import "package:angular2/src/facade/lang.dart" show Type;
import "package:angular2/src/facade/async.dart"
    show PromiseWrapper, ObservableWrapper;
import "package:angular2/src/facade/collection.dart" show ListWrapper;
import "package:angular2/src/router/router.dart" show Router, RootRouter;
import "package:angular2/src/mock/location_mock.dart" show SpyLocation;
import "package:angular2/src/router/location/location.dart" show Location;
import "package:angular2/src/router/route_registry.dart"
    show RouteRegistry, ROUTER_PRIMARY_COMPONENT;
import "package:angular2/src/router/route_config/route_config_decorator.dart"
    show RouteConfig, AsyncRoute, Route, Redirect;
import "package:angular2/src/core/linker/directive_resolver.dart"
    show DirectiveResolver;
import "package:angular2/core.dart" show provide;
import "package:angular2/src/router/directives/router_outlet.dart"
    show RouterOutlet;

main() {
  describe("Router", () {
    Router router;
    Location location;
    beforeEachProviders(() => [
          RouteRegistry,
          DirectiveResolver,
          provide(Location, useClass: SpyLocation),
          provide(ROUTER_PRIMARY_COMPONENT, useValue: AppCmp),
          provide(Router, useClass: RootRouter)
        ]);
    beforeEach(inject([Router, Location], (Router rtr, Location loc) {
      router = rtr;
      location = loc;
    }));
    it(
        "should navigate based on the initial URL state",
        inject([AsyncTestCompleter], (async) {
          var outlet = makeDummyOutlet();
          router
              .config([new Route(path: "/", component: DummyComponent)])
              .then((_) => router.registerPrimaryOutlet(outlet))
              .then((_) {
                expect(((outlet as dynamic)).spy("activate"))
                    .toHaveBeenCalled();
                expect(((location as SpyLocation)).urlChanges).toEqual([]);
                async.done();
              });
        }));
    it(
        "should activate viewports and update URL on navigate",
        inject([AsyncTestCompleter], (async) {
          var outlet = makeDummyOutlet();
          router
              .registerPrimaryOutlet(outlet)
              .then((_) => router
                  .config([new Route(path: "/a", component: DummyComponent)]))
              .then((_) => router.navigateByUrl("/a"))
              .then((_) {
            expect(((outlet as dynamic)).spy("activate")).toHaveBeenCalled();
            expect(((location as SpyLocation)).urlChanges).toEqual(["/a"]);
            async.done();
          });
        }));
    it(
        "should activate viewports and update URL when navigating via DSL",
        inject([AsyncTestCompleter], (async) {
          var outlet = makeDummyOutlet();
          router
              .registerPrimaryOutlet(outlet)
              .then((_) => router.config([
                    new Route(path: "/a", component: DummyComponent, name: "A")
                  ]))
              .then((_) => router.navigate(["/A"]))
              .then((_) {
            expect(((outlet as dynamic)).spy("activate")).toHaveBeenCalled();
            expect(((location as SpyLocation)).urlChanges).toEqual(["/a"]);
            async.done();
          });
        }));
    it(
        "should not push a history change on when navigate is called with skipUrlChange",
        inject([AsyncTestCompleter], (async) {
          var outlet = makeDummyOutlet();
          router
              .registerPrimaryOutlet(outlet)
              .then((_) => router
                  .config([new Route(path: "/b", component: DummyComponent)]))
              .then((_) => router.navigateByUrl("/b", true))
              .then((_) {
            expect(((outlet as dynamic)).spy("activate")).toHaveBeenCalled();
            expect(((location as SpyLocation)).urlChanges).toEqual([]);
            async.done();
          });
        }));
    // See https://github.com/angular/angular/issues/5590

    // This test is disabled because it is flaky.

    // TODO: bford. make this test not flaky and reenable it.
    xit(
        "should replace history when triggered by a hashchange with a redirect",
        inject([AsyncTestCompleter], (async) {
          var outlet = makeDummyOutlet();
          router
              .registerPrimaryOutlet(outlet)
              .then((_) => router.config([
                    new Redirect(path: "/a", redirectTo: ["B"]),
                    new Route(path: "/b", component: DummyComponent, name: "B")
                  ]))
              .then((_) {
            router.subscribe((_) {
              expect(((location as SpyLocation)).urlChanges)
                  .toEqual(["hash: a", "replace: /b"]);
              async.done();
            });
            ((location as SpyLocation)).simulateHashChange("a");
          });
        }));
    it(
        "should push history when triggered by a hashchange without a redirect",
        inject([AsyncTestCompleter], (async) {
          var outlet = makeDummyOutlet();
          router
              .registerPrimaryOutlet(outlet)
              .then((_) => router
                  .config([new Route(path: "/a", component: DummyComponent)]))
              .then((_) {
            router.subscribe((_) {
              expect(((location as SpyLocation)).urlChanges)
                  .toEqual(["hash: a"]);
              async.done();
            });
            ((location as SpyLocation)).simulateHashChange("a");
          });
        }));
    it(
        "should navigate after being configured",
        inject([AsyncTestCompleter], (async) {
          var outlet = makeDummyOutlet();
          router
              .registerPrimaryOutlet(outlet)
              .then((_) => router.navigateByUrl("/a"))
              .then((_) {
            expect(((outlet as dynamic)).spy("activate"))
                .not
                .toHaveBeenCalled();
            return router
                .config([new Route(path: "/a", component: DummyComponent)]);
          }).then((_) {
            expect(((outlet as dynamic)).spy("activate")).toHaveBeenCalled();
            async.done();
          });
        }));
    it("should throw when linkParams does not include a route name", () {
      expect(() => router.generate(["./"])).toThrowError(
          '''Link "${ ListWrapper . toJSON ( [ "./" ] )}" must include a route name.''');
      expect(() => router.generate(["/"])).toThrowError(
          '''Link "${ ListWrapper . toJSON ( [ "/" ] )}" must include a route name.''');
    });
    it("should, when subscribed to, return a disposable subscription", () {
      expect(() {
        var subscription = router.subscribe((_) {});
        ObservableWrapper.dispose(subscription);
      }).not.toThrow();
    });
    it("should generate URLs from the root component when the path starts with /",
        () {
      router.config([
        new Route(
            path: "/first/...", component: DummyParentComp, name: "FirstCmp")
      ]);
      var instruction = router.generate(["/FirstCmp", "SecondCmp"]);
      expect(stringifyInstruction(instruction)).toEqual("first/second");
      instruction = router.generate(["/FirstCmp/SecondCmp"]);
      expect(stringifyInstruction(instruction)).toEqual("first/second");
    });
    it(
        "should generate an instruction with terminal async routes",
        inject([AsyncTestCompleter], (async) {
          var outlet = makeDummyOutlet();
          router.registerPrimaryOutlet(outlet);
          router.config([
            new AsyncRoute(path: "/first", loader: loader, name: "FirstCmp")
          ]);
          var instruction = router.generate(["/FirstCmp"]);
          router.navigateByInstruction(instruction).then((_) {
            expect(((outlet as dynamic)).spy("activate")).toHaveBeenCalled();
            async.done();
          });
        }));
    it(
        "should return whether a given instruction is active with isRouteActive",
        inject([AsyncTestCompleter], (async) {
          var outlet = makeDummyOutlet();
          router
              .registerPrimaryOutlet(outlet)
              .then((_) => router.config([
                    new Route(path: "/a", component: DummyComponent, name: "A"),
                    new Route(path: "/b", component: DummyComponent, name: "B")
                  ]))
              .then((_) => router.navigateByUrl("/a"))
              .then((_) {
            var instruction = router.generate(["/A"]);
            var otherInstruction = router.generate(["/B"]);
            expect(router.isRouteActive(instruction)).toEqual(true);
            expect(router.isRouteActive(otherInstruction)).toEqual(false);
            async.done();
          });
        }));
    it(
        "should provide the current instruction",
        inject([AsyncTestCompleter], (async) {
          var outlet = makeDummyOutlet();
          router
              .registerPrimaryOutlet(outlet)
              .then((_) => router.config([
                    new Route(path: "/a", component: DummyComponent, name: "A"),
                    new Route(path: "/b", component: DummyComponent, name: "B")
                  ]))
              .then((_) => router.navigateByUrl("/a"))
              .then((_) {
            var instruction = router.generate(["/A"]);
            expect(router.currentInstruction).toEqual(instruction);
            async.done();
          });
        }));
    it("should provide the root level router from child routers", () {
      var childRouter = router.childRouter(DummyComponent);
      expect(childRouter.root).toBe(router);
    });
    describe("query string params", () {
      it("should use query string params for the root route", () {
        router.config([
          new Route(
              path: "/hi/how/are/you",
              component: DummyComponent,
              name: "GreetingUrl")
        ]);
        var instruction = router.generate([
          "/GreetingUrl",
          {"name": "brad"}
        ]);
        var path = stringifyInstruction(instruction);
        expect(path).toEqual("hi/how/are/you?name=brad");
      });
      it("should preserve the number 1 as a query string value", () {
        router.config([
          new Route(
              path: "/hi/how/are/you",
              component: DummyComponent,
              name: "GreetingUrl")
        ]);
        var instruction = router.generate([
          "/GreetingUrl",
          {"name": 1}
        ]);
        var path = stringifyInstruction(instruction);
        expect(path).toEqual("hi/how/are/you?name=1");
      });
      it("should serialize parameters that are not part of the route definition as query string params",
          () {
        router.config([
          new Route(
              path: "/one/two/:three",
              component: DummyComponent,
              name: "NumberUrl")
        ]);
        var instruction = router.generate([
          "/NumberUrl",
          {"three": "three", "four": "four"}
        ]);
        var path = stringifyInstruction(instruction);
        expect(path).toEqual("one/two/three?four=four");
      });
    });
    describe("matrix params", () {
      it("should generate matrix params for each non-root component", () {
        router.config([
          new Route(
              path: "/first/...", component: DummyParentComp, name: "FirstCmp")
        ]);
        var instruction = router.generate([
          "/FirstCmp",
          {"key": "value"},
          "SecondCmp",
          {"project": "angular"}
        ]);
        var path = stringifyInstruction(instruction);
        expect(path).toEqual("first/second;project=angular?key=value");
      });
      it("should work with named params", () {
        router.config([
          new Route(
              path: "/first/:token/...",
              component: DummyParentComp,
              name: "FirstCmp")
        ]);
        var instruction = router.generate([
          "/FirstCmp",
          {"token": "min"},
          "SecondCmp",
          {"author": "max"}
        ]);
        var path = stringifyInstruction(instruction);
        expect(path).toEqual("first/min/second;author=max");
      });
    });
  });
}

String stringifyInstruction(instruction) {
  return instruction.toRootUrl();
}

Future<Type> loader() {
  return PromiseWrapper.resolve(DummyComponent);
}

class DummyComponent {}

@RouteConfig(const [
  const Route(path: "/second", component: DummyComponent, name: "SecondCmp")
])
class DummyParentComp {}

RouterOutlet makeDummyOutlet() {
  var ref = new SpyRouterOutlet();
  ref.spy("canActivate").andCallFake((_) => PromiseWrapper.resolve(true));
  ref.spy("routerCanReuse").andCallFake((_) => PromiseWrapper.resolve(false));
  ref
      .spy("routerCanDeactivate")
      .andCallFake((_) => PromiseWrapper.resolve(true));
  ref.spy("activate").andCallFake((_) => PromiseWrapper.resolve(true));
  return (ref as dynamic);
}

class AppCmp {}
