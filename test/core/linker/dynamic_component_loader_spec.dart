library angular2.test.core.linker.dynamic_component_loader_spec;

import "package:angular2/testing_internal.dart"
    show
        AsyncTestCompleter,
        beforeEach,
        ddescribe,
        xdescribe,
        describe,
        el,
        dispatchEvent,
        expect,
        iit,
        inject,
        beforeEachProviders,
        it,
        xit,
        TestComponentBuilder,
        ComponentFixture;
import "package:angular2/core.dart" show OnDestroy;
import "package:angular2/core.dart" show Injector;
import "package:angular2/common.dart" show NgIf;
import "package:angular2/src/core/metadata.dart"
    show Component, View, ViewMetadata;
import "package:angular2/src/core/linker/dynamic_component_loader.dart"
    show DynamicComponentLoader;
import "package:angular2/src/core/linker/element_ref.dart"
    show ElementRef, ElementRef_;
import "package:angular2/src/platform/dom/dom_tokens.dart" show DOCUMENT;
import "package:angular2/src/platform/dom/dom_adapter.dart" show DOM;
import "package:angular2/src/testing/test_component_builder.dart"
    show ComponentFixture_;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/src/facade/promise.dart" show PromiseWrapper;
import "package:angular2/src/facade/lang.dart" show stringify;

main() {
  describe("DynamicComponentLoader", () {
    describe("loading into a location", () {
      it(
          "should work",
          inject([
            DynamicComponentLoader,
            TestComponentBuilder,
            AsyncTestCompleter
          ], (loader, TestComponentBuilder tcb, async) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template: "<location #loc></location>",
                        directives: [Location]))
                .createAsync(MyComp)
                .then((tc) {
              loader
                  .loadIntoLocation(DynamicallyLoaded, tc.elementRef, "loc")
                  .then((ref) {
                expect(tc.debugElement.nativeElement)
                    .toHaveText("Location;DynamicallyLoaded;");
                async.done();
              });
            });
          }));
      it(
          "should return a disposable component ref",
          inject([
            DynamicComponentLoader,
            TestComponentBuilder,
            AsyncTestCompleter
          ], (loader, TestComponentBuilder tcb, async) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template: "<location #loc></location>",
                        directives: [Location]))
                .createAsync(MyComp)
                .then((tc) {
              loader
                  .loadIntoLocation(DynamicallyLoaded, tc.elementRef, "loc")
                  .then((ref) {
                ref.dispose();
                expect(tc.debugElement.nativeElement).toHaveText("Location;");
                async.done();
              });
            });
          }));
      it(
          "should allow to dispose even if the location has been removed",
          inject([
            DynamicComponentLoader,
            TestComponentBuilder,
            AsyncTestCompleter
          ], (loader, TestComponentBuilder tcb, async) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template:
                            "<child-cmp *ngIf=\"ctxBoolProp\"></child-cmp>",
                        directives: [NgIf, ChildComp]))
                .overrideView(
                    ChildComp,
                    new ViewMetadata(
                        template: "<location #loc></location>",
                        directives: [Location]))
                .createAsync(MyComp)
                .then((tc) {
              tc.debugElement.componentInstance.ctxBoolProp = true;
              tc.detectChanges();
              var childCompEl =
                  ((tc.elementRef as ElementRef_)).internalElement;
              // TODO(juliemr): This is hideous, see if there's a better way to handle

              // child element refs now.
              var childElementRef = childCompEl.componentView.appElements[0]
                  .nestedViews[0].appElements[0].ref;
              loader
                  .loadIntoLocation(DynamicallyLoaded, childElementRef, "loc")
                  .then((ref) {
                expect(tc.debugElement.nativeElement)
                    .toHaveText("Location;DynamicallyLoaded;");
                tc.debugElement.componentInstance.ctxBoolProp = false;
                tc.detectChanges();
                expect(tc.debugElement.nativeElement).toHaveText("");
                ref.dispose();
                expect(tc.debugElement.nativeElement).toHaveText("");
                async.done();
              });
            });
          }));
      it(
          "should update host properties",
          inject([
            DynamicComponentLoader,
            TestComponentBuilder,
            AsyncTestCompleter
          ], (loader, TestComponentBuilder tcb, async) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template: "<location #loc></location>",
                        directives: [Location]))
                .createAsync(MyComp)
                .then((tc) {
              loader
                  .loadIntoLocation(
                      DynamicallyLoadedWithHostProps, tc.elementRef, "loc")
                  .then((ref) {
                ref.instance.id = "new value";
                tc.detectChanges();
                var newlyInsertedElement =
                    DOM.childNodes(tc.debugElement.nativeElement)[1];
                expect(((newlyInsertedElement as dynamic)).id)
                    .toEqual("new value");
                async.done();
              });
            });
          }));
      it(
          "should leave the view tree in a consistent state if hydration fails",
          inject([
            DynamicComponentLoader,
            TestComponentBuilder,
            AsyncTestCompleter
          ], (loader, TestComponentBuilder tcb, async) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template: "<div><location #loc></location></div>",
                        directives: [Location]))
                .createAsync(MyComp)
                .then((ComponentFixture tc) {
              tc.debugElement;
              PromiseWrapper.catchError(
                  loader.loadIntoLocation(
                      DynamicallyLoadedThrows, tc.elementRef, "loc"), (error) {
                expect(error.message).toContain("ThrownInConstructor");
                expect(() => tc.detectChanges()).not.toThrow();
                async.done();
              });
            });
          }));
      it(
          "should throw if the variable does not exist",
          inject([
            DynamicComponentLoader,
            TestComponentBuilder,
            AsyncTestCompleter
          ], (loader, TestComponentBuilder tcb, async) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template: "<location #loc></location>",
                        directives: [Location]))
                .createAsync(MyComp)
                .then((tc) {
              expect(() => loader.loadIntoLocation(
                      DynamicallyLoadedWithHostProps,
                      tc.elementRef,
                      "someUnknownVariable"))
                  .toThrowError("Could not find variable someUnknownVariable");
              async.done();
            });
          }));
      it(
          "should allow to pass projectable nodes",
          inject([
            DynamicComponentLoader,
            TestComponentBuilder,
            AsyncTestCompleter
          ], (loader, TestComponentBuilder tcb, async) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template: "<div #loc></div>", directives: []))
                .createAsync(MyComp)
                .then((tc) {
              loader.loadIntoLocation(
                  DynamicallyLoadedWithNgContent, tc.elementRef, "loc", null, [
                [DOM.createTextNode("hello")]
              ]).then((ref) {
                tc.detectChanges();
                expect(tc.nativeElement).toHaveText("dynamic(hello)");
                async.done();
              });
            });
          }));
      it(
          "should throw if not enough projectable nodes are passed in",
          inject([
            DynamicComponentLoader,
            TestComponentBuilder,
            AsyncTestCompleter
          ], (loader, TestComponentBuilder tcb, async) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template: "<div #loc></div>", directives: []))
                .createAsync(MyComp)
                .then((tc) {
              PromiseWrapper.catchError(
                  loader.loadIntoLocation(DynamicallyLoadedWithNgContent,
                      tc.elementRef, "loc", null, []), (e) {
                expect(e.message).toContain(
                    '''The component ${ stringify ( DynamicallyLoadedWithNgContent )} has 1 <ng-content> elements, but only 0 slots were provided''');
                async.done();
              });
            });
          }));
    });
    describe("loading next to a location", () {
      it(
          "should work",
          inject([
            DynamicComponentLoader,
            TestComponentBuilder,
            AsyncTestCompleter
          ], (loader, TestComponentBuilder tcb, async) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template: "<div><location #loc></location></div>",
                        directives: [Location]))
                .createAsync(MyComp)
                .then((tc) {
              loader
                  .loadNextToLocation(DynamicallyLoaded, tc.elementRef)
                  .then((ref) {
                expect(tc.debugElement.nativeElement).toHaveText("Location;");
                expect(DOM.nextSibling(tc.debugElement.nativeElement))
                    .toHaveText("DynamicallyLoaded;");
                async.done();
              });
            });
          }));
      it(
          "should return a disposable component ref",
          inject([
            DynamicComponentLoader,
            TestComponentBuilder,
            AsyncTestCompleter
          ], (loader, TestComponentBuilder tcb, async) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template: "<div><location #loc></location></div>",
                        directives: [Location]))
                .createAsync(MyComp)
                .then((tc) {
              loader
                  .loadNextToLocation(DynamicallyLoaded, tc.elementRef)
                  .then((ref) {
                loader
                    .loadNextToLocation(DynamicallyLoaded2, tc.elementRef)
                    .then((ref2) {
                  var firstSibling =
                      DOM.nextSibling(tc.debugElement.nativeElement);
                  var secondSibling = DOM.nextSibling(firstSibling);
                  expect(tc.debugElement.nativeElement).toHaveText("Location;");
                  expect(firstSibling).toHaveText("DynamicallyLoaded;");
                  expect(secondSibling).toHaveText("DynamicallyLoaded2;");
                  ref2.dispose();
                  firstSibling = DOM.nextSibling(tc.debugElement.nativeElement);
                  secondSibling = DOM.nextSibling(firstSibling);
                  expect(secondSibling).toBeNull();
                  async.done();
                });
              });
            });
          }));
      it(
          "should update host properties",
          inject([
            DynamicComponentLoader,
            TestComponentBuilder,
            AsyncTestCompleter
          ], (loader, TestComponentBuilder tcb, async) {
            tcb
                .overrideView(
                    MyComp,
                    new ViewMetadata(
                        template: "<div><location #loc></location></div>",
                        directives: [Location]))
                .createAsync(MyComp)
                .then((tc) {
              loader
                  .loadNextToLocation(
                      DynamicallyLoadedWithHostProps, tc.elementRef)
                  .then((ref) {
                ref.instance.id = "new value";
                tc.detectChanges();
                var newlyInsertedElement =
                    DOM.nextSibling(tc.debugElement.nativeElement);
                expect(((newlyInsertedElement as dynamic)).id)
                    .toEqual("new value");
                async.done();
              });
            });
          }));
      it(
          "should allow to pass projectable nodes",
          inject([
            DynamicComponentLoader,
            TestComponentBuilder,
            AsyncTestCompleter
          ], (loader, TestComponentBuilder tcb, async) {
            tcb
                .overrideView(MyComp,
                    new ViewMetadata(template: "", directives: [Location]))
                .createAsync(MyComp)
                .then((tc) {
              loader.loadNextToLocation(
                  DynamicallyLoadedWithNgContent, tc.elementRef, null, [
                [DOM.createTextNode("hello")]
              ]).then((ref) {
                tc.detectChanges();
                var newlyInsertedElement =
                    DOM.nextSibling(tc.debugElement.nativeElement);
                expect(newlyInsertedElement).toHaveText("dynamic(hello)");
                async.done();
              });
            });
          }));
    });
    describe("loadAsRoot", () {
      it(
          "should allow to create, update and destroy components",
          inject(
              [AsyncTestCompleter, DynamicComponentLoader, DOCUMENT, Injector],
              (async, loader, doc, injector) {
            var rootEl = createRootElement(doc, "child-cmp");
            DOM.appendChild(doc.body, rootEl);
            loader.loadAsRoot(ChildComp, null, injector).then((componentRef) {
              var el = new ComponentFixture_(componentRef);
              expect(rootEl.parentNode).toBe(doc.body);
              el.detectChanges();
              expect(rootEl).toHaveText("hello");
              componentRef.instance.ctxProp = "new";
              el.detectChanges();
              expect(rootEl).toHaveText("new");
              componentRef.dispose();
              expect(rootEl.parentNode).toBeFalsy();
              async.done();
            });
          }));
      it(
          "should allow to pass projectable nodes",
          inject(
              [AsyncTestCompleter, DynamicComponentLoader, DOCUMENT, Injector],
              (async, loader, doc, injector) {
            var rootEl = createRootElement(doc, "dummy");
            DOM.appendChild(doc.body, rootEl);
            loader.loadAsRoot(
                DynamicallyLoadedWithNgContent, null, injector, null, [
              [DOM.createTextNode("hello")]
            ]).then((_) {
              expect(rootEl).toHaveText("dynamic(hello)");
              async.done();
            });
          }));
    });
  });
}

dynamic createRootElement(dynamic doc, String name) {
  var nodes = DOM.querySelectorAll(doc, name);
  for (var i = 0; i < nodes.length; i++) {
    DOM.remove(nodes[i]);
  }
  var rootEl = el('''<${ name}></${ name}>''');
  DOM.appendChild(doc.body, rootEl);
  return rootEl;
}

@Component(selector: "child-cmp")
@View(template: "{{ctxProp}}")
class ChildComp {
  String ctxProp;
  ChildComp() {
    this.ctxProp = "hello";
  }
}

class DynamicallyCreatedComponentService {}

@Component(
    selector: "hello-cmp",
    viewProviders: const [DynamicallyCreatedComponentService])
@View(template: "{{greeting}}")
class DynamicallyCreatedCmp implements OnDestroy {
  String greeting;
  DynamicallyCreatedComponentService dynamicallyCreatedComponentService;
  bool destroyed = false;
  DynamicallyCreatedCmp(DynamicallyCreatedComponentService a) {
    this.greeting = "hello";
    this.dynamicallyCreatedComponentService = a;
  }
  ngOnDestroy() {
    this.destroyed = true;
  }
}

@Component(selector: "dummy")
@View(template: "DynamicallyLoaded;")
class DynamicallyLoaded {}

@Component(selector: "dummy")
@View(template: "DynamicallyLoaded;")
class DynamicallyLoadedThrows {
  DynamicallyLoadedThrows() {
    throw new BaseException("ThrownInConstructor");
  }
}

@Component(selector: "dummy")
@View(template: "DynamicallyLoaded2;")
class DynamicallyLoaded2 {}

@Component(selector: "dummy", host: const {"[id]": "id"})
@View(template: "DynamicallyLoadedWithHostProps;")
class DynamicallyLoadedWithHostProps {
  String id;
  DynamicallyLoadedWithHostProps() {
    this.id = "default";
  }
}

@Component(selector: "dummy")
@View(template: "dynamic(<ng-content></ng-content>)")
class DynamicallyLoadedWithNgContent {
  String id;
  DynamicallyLoadedWithNgContent() {
    this.id = "default";
  }
}

@Component(selector: "location")
@View(template: "Location;")
class Location {
  ElementRef elementRef;
  Location(ElementRef elementRef) {
    this.elementRef = elementRef;
  }
}

@Component(selector: "my-comp")
@View(directives: const [])
class MyComp {
  bool ctxBoolProp;
  MyComp() {
    this.ctxBoolProp = false;
  }
}
