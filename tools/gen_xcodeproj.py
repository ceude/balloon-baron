"""Writes BalloonBaron.xcodeproj/project.pbxproj in the classic format (objectVersion 56) that
Xcode 14 and 15 can open. Every file under BalloonBaron/ is listed explicitly, so run this again
after adding or removing files: python3 tools/gen_xcodeproj.py"""
import hashlib, os

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
APP = "BalloonBaron"
PACKAGE = "Packages/BalloonBaronCore"
# Folders Xcode treats as a single resource.
BUNDLES = (".xcassets",)
SKIP = {".DS_Store"}


def oid(*parts):
    """Stable 24-hex-digit object id, so regenerating gives the same file."""
    return hashlib.md5("/".join(parts).encode()).hexdigest()[:24].upper()


def kind(name):
    ext = os.path.splitext(name)[1]
    return {".swift": "sourcecode.swift", ".xcassets": "folder.assetcatalog", ".xcstrings": "text.json.xcstrings",
            ".ttf": "file", ".json": "text.json", ".plist": "text.plist.xml", ".xcprivacy": "text.xml"}.get(ext, "file")


def scan(rel):
    """Returns (subgroups, files) for a folder, both sorted."""
    groups, files = [], []
    for name in sorted(os.listdir(os.path.join(ROOT, rel)), key=str.lower):
        if name in SKIP:
            continue
        path = rel + "/" + name  # always "/", so ids match whether this runs on a Mac or on Windows
        if os.path.isdir(os.path.join(ROOT, path)) and not name.endswith(BUNDLES):
            groups.append(path)
        else:
            files.append(path)
    return groups, files


objects = {}  # id -> (isa, body lines)
sources, resources = [], []


def add_group(rel):
    gid = oid("group", rel)
    groups, files = scan(rel)
    children = []
    for g in groups:
        children.append((add_group(g), os.path.basename(g)))
    for f in files:
        fid = oid("file", f)
        name = os.path.basename(f)
        objects[fid] = ("PBXFileReference", f"{{isa = PBXFileReference; lastKnownFileType = {kind(name)}; path = \"{name}\"; sourceTree = \"<group>\"; }}", name)
        bid = oid("build", f)
        if name.endswith(".swift"):
            sources.append((bid, fid, name))
        else:
            resources.append((bid, fid, name))
        children.append((fid, name))
    body = "{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n" + "".join(f"\t\t\t\t{c} /* {n} */,\n" for c, n in children) + \
        f"\t\t\t);\n\t\t\tpath = \"{os.path.basename(rel)}\";\n\t\t\tsourceTree = \"<group>\";\n\t\t}}"
    objects[gid] = ("PBXGroup", body, os.path.basename(rel))
    return gid


app_group = add_group(APP)

MAIN, PRODUCTS, PACKAGES = oid("main"), oid("products"), oid("packages")
PRODUCT, TARGET, PROJECT = oid("product"), oid("target"), oid("project")
SRC_PHASE, RES_PHASE, FW_PHASE = oid("phase.sources"), oid("phase.resources"), oid("phase.frameworks")
PKG_REF, PKG_DEP, PKG_BUILD = oid("package.ref"), oid("package.dep"), oid("package.build")
PROJ_LIST, TARGET_LIST = oid("list.project"), oid("list.target")
PROJ_DEBUG, PROJ_RELEASE = oid("config.project.debug"), oid("config.project.release")
TGT_DEBUG, TGT_RELEASE = oid("config.target.debug"), oid("config.target.release")

COMMON = """ALWAYS_SEARCH_USER_PATHS = NO;
ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
CLANG_ANALYZER_NONNULL = YES;
CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
CLANG_ENABLE_MODULES = YES;
CLANG_ENABLE_OBJC_ARC = YES;
CLANG_WARN_BOOL_CONVERSION = YES;
CLANG_WARN_CONSTANT_CONVERSION = YES;
CLANG_WARN_EMPTY_BODY = YES;
CLANG_WARN_ENUM_CONVERSION = YES;
CLANG_WARN_INFINITE_RECURSION = YES;
CLANG_WARN_INT_CONVERSION = YES;
CLANG_WARN_UNREACHABLE_CODE = YES;
COPY_PHASE_STRIP = NO;
ENABLE_STRICT_OBJC_MSGSEND = YES;
ENABLE_USER_SCRIPT_SANDBOXING = YES;
GCC_C_LANGUAGE_STANDARD = gnu17;
GCC_NO_COMMON_BLOCKS = YES;
GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
GCC_WARN_UNDECLARED_SELECTOR = YES;
GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
GCC_WARN_UNUSED_FUNCTION = YES;
GCC_WARN_UNUSED_VARIABLE = YES;
IPHONEOS_DEPLOYMENT_TARGET = 17.0;
LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
SDKROOT = iphoneos;"""
PROJ_DEBUG_EXTRA = """DEBUG_INFORMATION_FORMAT = dwarf;
ENABLE_TESTABILITY = YES;
GCC_DYNAMIC_NO_PIC = NO;
GCC_OPTIMIZATION_LEVEL = 0;
GCC_PREPROCESSOR_DEFINITIONS = (
\t"DEBUG=1",
\t"$(inherited)",
);
MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
ONLY_ACTIVE_ARCH = YES;
SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
SWIFT_OPTIMIZATION_LEVEL = "-Onone";"""
PROJ_RELEASE_EXTRA = """DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
ENABLE_NS_ASSERTIONS = NO;
MTL_ENABLE_DEBUG_INFO = NO;
SWIFT_COMPILATION_MODE = wholemodule;
VALIDATE_PRODUCT = YES;"""
TARGET_SETTINGS = """ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
CODE_SIGN_STYLE = Automatic;
CURRENT_PROJECT_VERSION = 1;
ENABLE_PREVIEWS = YES;
GENERATE_INFOPLIST_FILE = YES;
INFOPLIST_KEY_CFBundleDisplayName = "Balloon Baron";
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO;
INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.simulation-games";
INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
INFOPLIST_KEY_UILaunchScreen_Generation = YES;
INFOPLIST_KEY_UIRequiresFullScreen = YES;
INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = UIInterfaceOrientationPortrait;
INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = UIInterfaceOrientationPortrait;
LD_RUNPATH_SEARCH_PATHS = (
\t"$(inherited)",
\t"@executable_path/Frameworks",
);
MARKETING_VERSION = 1.0;
PRODUCT_BUNDLE_IDENTIFIER = com.ceude.balloonbaron;
PRODUCT_NAME = "$(TARGET_NAME)";
SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
SUPPORTS_MACCATALYST = NO;
SWIFT_EMIT_LOC_STRINGS = YES;
SWIFT_VERSION = 5.0;
TARGETED_DEVICE_FAMILY = "1,2";"""


def settings(text):
    return "".join(f"\t\t\t\t{line}\n" for line in text.split("\n"))


def config(cid, name, text):
    return cid, "XCBuildConfiguration", f"{{\n\t\t\tisa = XCBuildConfiguration;\n\t\t\tbuildSettings = {{\n{settings(text)}\t\t\t}};\n\t\t\tname = {name};\n\t\t}}", name


def phase(pid, isa, name, items):
    files = "".join(f"\t\t\t\t{b} /* {n} in {name} */,\n" for b, _, n in items)
    return f"{{\n\t\t\tisa = {isa};\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n{files}\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}}"


sections = {}


def put(isa, id_, body, comment):
    sections.setdefault(isa, []).append((id_, body, comment))


for id_, (isa, body, comment) in objects.items():
    put(isa, id_, body, comment)
for b, f, n in sources:
    put("PBXBuildFile", b, f"{{isa = PBXBuildFile; fileRef = {f} /* {n} */; }}", f"{n} in Sources")
for b, f, n in resources:
    put("PBXBuildFile", b, f"{{isa = PBXBuildFile; fileRef = {f} /* {n} */; }}", f"{n} in Resources")
put("PBXBuildFile", PKG_BUILD, f"{{isa = PBXBuildFile; productRef = {PKG_DEP} /* BalloonBaronCore */; }}", "BalloonBaronCore in Frameworks")
put("PBXFileReference", PRODUCT, "{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = BalloonBaron.app; sourceTree = BUILT_PRODUCTS_DIR; }", "BalloonBaron.app")
# The local package is referenced as a folder, which every Xcode since 11 understands.
put("PBXFileReference", PKG_REF, f"{{isa = PBXFileReference; lastKnownFileType = wrapper; name = BalloonBaronCore; path = {PACKAGE}; sourceTree = \"<group>\"; }}", "BalloonBaronCore")
put("PBXGroup", MAIN, f"{{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t{PACKAGES} /* Packages */,\n\t\t\t\t{app_group} /* {APP} */,\n\t\t\t\t{PRODUCTS} /* Products */,\n\t\t\t);\n\t\t\tsourceTree = \"<group>\";\n\t\t}}", "")
put("PBXGroup", PACKAGES, f"{{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t{PKG_REF} /* BalloonBaronCore */,\n\t\t\t);\n\t\t\tname = Packages;\n\t\t\tsourceTree = \"<group>\";\n\t\t}}", "Packages")
put("PBXGroup", PRODUCTS, f"{{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t{PRODUCT} /* BalloonBaron.app */,\n\t\t\t);\n\t\t\tname = Products;\n\t\t\tsourceTree = \"<group>\";\n\t\t}}", "Products")
put("PBXSourcesBuildPhase", SRC_PHASE, phase(SRC_PHASE, "PBXSourcesBuildPhase", "Sources", sources), "Sources")
put("PBXResourcesBuildPhase", RES_PHASE, phase(RES_PHASE, "PBXResourcesBuildPhase", "Resources", resources), "Resources")
put("PBXFrameworksBuildPhase", FW_PHASE, phase(FW_PHASE, "PBXFrameworksBuildPhase", "Frameworks", [(PKG_BUILD, None, "BalloonBaronCore")]), "Frameworks")
put("PBXNativeTarget", TARGET, f"""{{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {TARGET_LIST} /* Build configuration list for PBXNativeTarget "BalloonBaron" */;
\t\t\tbuildPhases = (
\t\t\t\t{SRC_PHASE} /* Sources */,
\t\t\t\t{FW_PHASE} /* Frameworks */,
\t\t\t\t{RES_PHASE} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = BalloonBaron;
\t\t\tpackageProductDependencies = (
\t\t\t\t{PKG_DEP} /* BalloonBaronCore */,
\t\t\t);
\t\t\tproductName = BalloonBaron;
\t\t\tproductReference = {PRODUCT} /* BalloonBaron.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}}""", "BalloonBaron")
put("PBXProject", PROJECT, f"""{{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 1500;
\t\t\t\tLastUpgradeCheck = 1500;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{TARGET} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {PROJ_LIST} /* Build configuration list for PBXProject "BalloonBaron" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t\ttr,
\t\t\t\tde,
\t\t\t\tes,
\t\t\t\tja,
\t\t\t\tko,
\t\t\t);
\t\t\tmainGroup = {MAIN};
\t\t\tproductRefGroup = {PRODUCTS} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{TARGET} /* BalloonBaron */,
\t\t\t);
\t\t}}""", "Project object")
for cid, isa, body, name in [config(PROJ_DEBUG, "Debug", COMMON + "\n" + PROJ_DEBUG_EXTRA), config(PROJ_RELEASE, "Release", COMMON + "\n" + PROJ_RELEASE_EXTRA),
                             config(TGT_DEBUG, "Debug", TARGET_SETTINGS), config(TGT_RELEASE, "Release", TARGET_SETTINGS)]:
    put(isa, cid, body, name)
for lid, debug, release, label in [(PROJ_LIST, PROJ_DEBUG, PROJ_RELEASE, 'PBXProject "BalloonBaron"'), (TARGET_LIST, TGT_DEBUG, TGT_RELEASE, 'PBXNativeTarget "BalloonBaron"')]:
    put("XCConfigurationList", lid, f"{{\n\t\t\tisa = XCConfigurationList;\n\t\t\tbuildConfigurations = (\n\t\t\t\t{debug} /* Debug */,\n\t\t\t\t{release} /* Release */,\n\t\t\t);\n\t\t\tdefaultConfigurationIsVisible = 0;\n\t\t\tdefaultConfigurationName = Release;\n\t\t}}", f"Build configuration list for {label}")
put("XCSwiftPackageProductDependency", PKG_DEP, "{\n\t\t\tisa = XCSwiftPackageProductDependency;\n\t\t\tproductName = BalloonBaronCore;\n\t\t}", "BalloonBaronCore")

out = ["// !$*UTF8*$!", "{", "\tarchiveVersion = 1;", "\tclasses = {", "\t};", "\tobjectVersion = 56;", "\tobjects = {"]
for isa in sorted(sections):
    out.append(f"\n/* Begin {isa} section */")
    for id_, body, comment in sorted(sections[isa]):
        c = f" /* {comment} */" if comment else ""
        out.append(f"\t\t{id_}{c} = {body};")
    out.append(f"/* End {isa} section */")
out += ["\t};", f"\trootObject = {PROJECT} /* Project object */;", "}", ""]
path = os.path.join(ROOT, "BalloonBaron.xcodeproj", "project.pbxproj")
open(path, "w", encoding="utf-8", newline="\n").write("\n".join(out))
print(f"{path}: {len(sources)} sources, {len(resources)} resources")
