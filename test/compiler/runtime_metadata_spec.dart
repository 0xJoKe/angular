library angular2.test.compiler.runtime_metadata_spec;

import "package:angular2/testing_internal.dart"
    show
        ddescribe,
        describe,
        xdescribe,
        it,
        iit,
        xit,
        expect,
        beforeEach,
        afterEach,
        AsyncTestCompleter,
        inject,
        beforeEachProviders;
import "package:angular2/src/facade/lang.dart" show stringify;
import "package:angular2/src/compiler/runtime_metadata.dart"
    show RuntimeMetadataResolver;
import "package:angular2/src/core/linker/interfaces.dart"
    show LifecycleHooks, LIFECYCLE_HOOKS_VALUES;
import "package:angular2/core.dart"
    show
        Component,
        View,
        Directive,
        ViewEncapsulation,
        ChangeDetectionStrategy,
        OnChanges,
        OnInit,
        DoCheck,
        OnDestroy,
        AfterContentInit,
        AfterContentChecked,
        AfterViewInit,
        AfterViewChecked,
        SimpleChange,
        provide;
import "test_bindings.dart" show TEST_PROVIDERS;
import "package:angular2/src/compiler/util.dart" show MODULE_SUFFIX;
import "package:angular2/src/facade/lang.dart" show IS_DART;
import "package:angular2/src/core/platform_directives_and_pipes.dart"
    show PLATFORM_DIRECTIVES;

main() {
  describe("RuntimeMetadataResolver", () {
    beforeEachProviders(() => TEST_PROVIDERS);
    describe("getMetadata", () {
      it(
          "should read metadata",
          inject([RuntimeMetadataResolver], (RuntimeMetadataResolver resolver) {
            var meta = resolver.getDirectiveMetadata(ComponentWithEverything);
            expect(meta.selector).toEqual("someSelector");
            expect(meta.exportAs).toEqual("someExportAs");
            expect(meta.isComponent).toBe(true);
            expect(meta.dynamicLoadable).toBe(true);
            expect(meta.type.runtime).toBe(ComponentWithEverything);
            expect(meta.type.name).toEqual(stringify(ComponentWithEverything));
            expect(meta.type.moduleUrl)
                .toEqual('''package:someModuleId${ MODULE_SUFFIX}''');
            expect(meta.lifecycleHooks).toEqual(LIFECYCLE_HOOKS_VALUES);
            expect(meta.changeDetection)
                .toBe(ChangeDetectionStrategy.CheckAlways);
            expect(meta.inputs).toEqual({"someProp": "someProp"});
            expect(meta.outputs).toEqual({"someEvent": "someEvent"});
            expect(meta.hostListeners)
                .toEqual({"someHostListener": "someHostListenerExpr"});
            expect(meta.hostProperties)
                .toEqual({"someHostProp": "someHostPropExpr"});
            expect(meta.hostAttributes)
                .toEqual({"someHostAttr": "someHostAttrValue"});
            expect(meta.template.encapsulation)
                .toBe(ViewEncapsulation.Emulated);
            expect(meta.template.styles).toEqual(["someStyle"]);
            expect(meta.template.styleUrls).toEqual(["someStyleUrl"]);
            expect(meta.template.template).toEqual("someTemplate");
            expect(meta.template.templateUrl).toEqual("someTemplateUrl");
          }));
      it(
          "should use the moduleUrl from the reflector if none is given",
          inject([RuntimeMetadataResolver], (RuntimeMetadataResolver resolver) {
            String value = resolver
                .getDirectiveMetadata(ComponentWithoutModuleId)
                .type
                .moduleUrl;
            var expectedEndValue =
                IS_DART ? "test/compiler/runtime_metadata_spec.dart" : "./";
            expect(value.endsWith(expectedEndValue)).toBe(true);
          }));
    });
    describe("getViewDirectivesMetadata", () {
      it(
          "should return the directive metadatas",
          inject([RuntimeMetadataResolver], (RuntimeMetadataResolver resolver) {
            expect(resolver.getViewDirectivesMetadata(ComponentWithEverything))
                .toContain(resolver.getDirectiveMetadata(SomeDirective));
          }));
      describe("platform directives", () {
        beforeEachProviders(() => [
              provide(PLATFORM_DIRECTIVES, useValue: [ADirective], multi: true)
            ]);
        it(
            "should include platform directives when available",
            inject([RuntimeMetadataResolver],
                (RuntimeMetadataResolver resolver) {
              expect(resolver
                      .getViewDirectivesMetadata(ComponentWithEverything))
                  .toContain(resolver.getDirectiveMetadata(ADirective));
              expect(resolver
                      .getViewDirectivesMetadata(ComponentWithEverything))
                  .toContain(resolver.getDirectiveMetadata(SomeDirective));
            }));
      });
    });
  });
}

@Directive(selector: "a-directive")
class ADirective {}

@Directive(selector: "someSelector")
class SomeDirective {}

@Component(selector: "someComponent", template: "")
class ComponentWithoutModuleId {}

@Component(
    selector: "someSelector",
    inputs: const ["someProp"],
    outputs: const ["someEvent"],
    host: const {
      "[someHostProp]": "someHostPropExpr",
      "(someHostListener)": "someHostListenerExpr",
      "someHostAttr": "someHostAttrValue"
    },
    exportAs: "someExportAs",
    moduleId: "someModuleId",
    changeDetection: ChangeDetectionStrategy.CheckAlways)
@View(
    template: "someTemplate",
    templateUrl: "someTemplateUrl",
    encapsulation: ViewEncapsulation.Emulated,
    styles: const ["someStyle"],
    styleUrls: const ["someStyleUrl"],
    directives: const [SomeDirective])
class ComponentWithEverything
    implements
        OnChanges,
        OnInit,
        DoCheck,
        OnDestroy,
        AfterContentInit,
        AfterContentChecked,
        AfterViewInit,
        AfterViewChecked {
  void ngOnChanges(Map<String, SimpleChange> changes) {}
  void ngOnInit() {}
  void ngDoCheck() {}
  void ngOnDestroy() {}
  void ngAfterContentInit() {}
  void ngAfterContentChecked() {}
  void ngAfterViewInit() {}
  void ngAfterViewChecked() {}
}
