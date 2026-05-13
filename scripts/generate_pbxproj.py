#!/usr/bin/env python3
"""Generate ExpenseTracker.xcodeproj/project.pbxproj from the source tree.

Run from repo root: python3 scripts/generate_pbxproj.py
"""
from __future__ import annotations

import hashlib
import os
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SRC_ROOT = REPO / "ExpenseTracker"
PROJECT_DIR = REPO / "ExpenseTracker.xcodeproj"
PBXPROJ = PROJECT_DIR / "project.pbxproj"

INFO_PLIST_REL = "ExpenseTracker/Info.plist"
ASSETS_REL = "ExpenseTracker/Assets.xcassets"


def uid(*parts: str) -> str:
    """Stable 24-char hex id from input parts."""
    h = hashlib.sha1("::".join(parts).encode()).hexdigest().upper()
    return h[:24]


def collect_swift_files() -> list[Path]:
    files: list[Path] = []
    for p in sorted(SRC_ROOT.rglob("*.swift")):
        files.append(p)
    return files


def rel(p: Path) -> str:
    return str(p.relative_to(REPO))


def build_groups(files: list[Path]) -> dict:
    """Build a nested dict representing the group tree under ExpenseTracker/."""
    root: dict = {"_files": [], "_dirs": {}}
    for f in files:
        parts = f.relative_to(SRC_ROOT).parts
        node = root
        for d in parts[:-1]:
            node = node["_dirs"].setdefault(d, {"_files": [], "_dirs": {}})
        node["_files"].append(f)
    return root


def main() -> None:
    swift_files = collect_swift_files()

    # Stable IDs
    project_id = uid("project")
    main_group_id = uid("mainGroup")
    products_group_id = uid("productsGroup")
    app_group_id = uid("appGroup")  # ExpenseTracker/ folder
    target_id = uid("target", "ExpenseTracker")
    product_ref_id = uid("product", "ExpenseTracker.app")
    sources_phase_id = uid("phase", "sources")
    resources_phase_id = uid("phase", "resources")
    frameworks_phase_id = uid("phase", "frameworks")
    config_list_proj_id = uid("configList", "project")
    config_list_target_id = uid("configList", "target")
    config_proj_debug_id = uid("config", "project", "Debug")
    config_proj_release_id = uid("config", "project", "Release")
    config_target_debug_id = uid("config", "target", "Debug")
    config_target_release_id = uid("config", "target", "Release")

    info_plist_id = uid("file", INFO_PLIST_REL)
    assets_id = uid("file", ASSETS_REL)
    assets_build_id = uid("buildFile", ASSETS_REL)

    file_refs: list[str] = []
    build_files: list[str] = []
    sources_build_refs: list[str] = []

    # Swift file refs + build files
    file_id_map: dict[Path, str] = {}
    build_id_map: dict[Path, str] = {}
    for f in swift_files:
        rp = rel(f)
        fid = uid("file", rp)
        bid = uid("buildFile", rp)
        file_id_map[f] = fid
        build_id_map[f] = bid
        file_refs.append(
            f'\t\t{fid} /* {f.name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{f.name}"; sourceTree = "<group>"; }};'
        )
        build_files.append(
            f'\t\t{bid} /* {f.name} in Sources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {f.name} */; }};'
        )
        sources_build_refs.append(f"\t\t\t\t{bid} /* {f.name} in Sources */,")

    # Info.plist file ref
    file_refs.append(
        f'\t\t{info_plist_id} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = "Info.plist"; sourceTree = "<group>"; }};'
    )

    # Assets file ref + build file
    file_refs.append(
        f'\t\t{assets_id} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = "Assets.xcassets"; sourceTree = "<group>"; }};'
    )
    build_files.append(
        f'\t\t{assets_build_id} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {assets_id} /* Assets.xcassets */; }};'
    )

    # Product
    file_refs.append(
        f'\t\t{product_ref_id} /* ExpenseTracker.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = "ExpenseTracker.app"; sourceTree = BUILT_PRODUCTS_DIR; }};'
    )

    # Build groups
    tree = build_groups(swift_files)

    group_blocks: list[str] = []

    def render_group(node: dict, name: str, path_segment: str, is_root: bool) -> str:
        children: list[str] = []
        # subdirs first, then files (alphabetical)
        for sub_name in sorted(node["_dirs"].keys()):
            sub_node = node["_dirs"][sub_name]
            sub_id = render_group(sub_node, sub_name, sub_name, is_root=False)
            children.append(f"\t\t\t\t{sub_id} /* {sub_name} */,")
        for f in sorted(node["_files"], key=lambda x: x.name):
            fid = file_id_map[f]
            children.append(f"\t\t\t\t{fid} /* {f.name} */,")
        # Inject Info.plist + Assets at the app group level only
        if is_root:
            children.append(f"\t\t\t\t{info_plist_id} /* Info.plist */,")
            children.append(f"\t\t\t\t{assets_id} /* Assets.xcassets */,")

        group_id = app_group_id if is_root else uid("group", name, path_segment)
        block = (
            f"\t\t{group_id} /* {name} */ = {{\n"
            f"\t\t\tisa = PBXGroup;\n"
            f"\t\t\tchildren = (\n"
            + "\n".join(children) + "\n"
            f"\t\t\t);\n"
            f'\t\t\tpath = "{path_segment}";\n'
            f"\t\t\tsourceTree = \"<group>\";\n"
            f"\t\t}};"
        )
        group_blocks.append(block)
        return group_id

    render_group(tree, "ExpenseTracker", "ExpenseTracker", is_root=True)

    # Products group
    group_blocks.append(
        f"\t\t{products_group_id} /* Products */ = {{\n"
        f"\t\t\tisa = PBXGroup;\n"
        f"\t\t\tchildren = (\n"
        f"\t\t\t\t{product_ref_id} /* ExpenseTracker.app */,\n"
        f"\t\t\t);\n"
        f"\t\t\tname = Products;\n"
        f"\t\t\tsourceTree = \"<group>\";\n"
        f"\t\t}};"
    )

    # Main group
    group_blocks.append(
        f"\t\t{main_group_id} = {{\n"
        f"\t\t\tisa = PBXGroup;\n"
        f"\t\t\tchildren = (\n"
        f"\t\t\t\t{app_group_id} /* ExpenseTracker */,\n"
        f"\t\t\t\t{products_group_id} /* Products */,\n"
        f"\t\t\t);\n"
        f"\t\t\tsourceTree = \"<group>\";\n"
        f"\t\t}};"
    )

    file_refs_section = "\n".join(file_refs)
    build_files_section = "\n".join(build_files)
    groups_section = "\n".join(group_blocks)
    sources_section = "\n".join(sources_build_refs)

    pbxproj = f"""// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{
\t}};
\tobjectVersion = 60;
\tobjects = {{

/* Begin PBXBuildFile section */
{build_files_section}
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
{file_refs_section}
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
\t\t{frameworks_phase_id} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
{groups_section}
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t{target_id} /* ExpenseTracker */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {config_list_target_id} /* Build configuration list for PBXNativeTarget "ExpenseTracker" */;
\t\t\tbuildPhases = (
\t\t\t\t{sources_phase_id} /* Sources */,
\t\t\t\t{frameworks_phase_id} /* Frameworks */,
\t\t\t\t{resources_phase_id} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = ExpenseTracker;
\t\t\tproductName = ExpenseTracker;
\t\t\tproductReference = {product_ref_id} /* ExpenseTracker.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t{project_id} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 1600;
\t\t\t\tLastUpgradeCheck = 1600;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{target_id} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {config_list_proj_id} /* Build configuration list for PBXProject "ExpenseTracker" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t);
\t\t\tmainGroup = {main_group_id};
\t\t\tproductRefGroup = {products_group_id} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{target_id} /* ExpenseTracker */,
\t\t\t);
\t\t}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t{resources_phase_id} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{assets_build_id} /* Assets.xcassets in Resources */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t{sources_phase_id} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{sources_section}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
\t\t{config_proj_debug_id} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (
\t\t\t\t\t"DEBUG=1",
\t\t\t\t\t"$(inherited)",
\t\t\t\t);
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 18.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t\tSWIFT_VERSION = 5.10;
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{config_proj_release_id} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 18.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-O";
\t\t\t\tSWIFT_VERSION = 5.10;
\t\t\t\tVALIDATE_PRODUCT = YES;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\t{config_target_debug_id} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tENABLE_PREVIEWS = YES;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = ExpenseTracker/Info.plist;
\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.expensetracker.kafy;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.10;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{config_target_release_id} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tENABLE_PREVIEWS = YES;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = ExpenseTracker/Info.plist;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.expensetracker.kafy;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.10;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t}};
\t\t\tname = Release;
\t\t}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t{config_list_proj_id} /* Build configuration list for PBXProject "ExpenseTracker" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{config_proj_debug_id} /* Debug */,
\t\t\t\t{config_proj_release_id} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{config_list_target_id} /* Build configuration list for PBXNativeTarget "ExpenseTracker" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{config_target_debug_id} /* Debug */,
\t\t\t\t{config_target_release_id} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
/* End XCConfigurationList section */
\t}};
\trootObject = {project_id} /* Project object */;
}}
"""

    PROJECT_DIR.mkdir(parents=True, exist_ok=True)
    PBXPROJ.write_text(pbxproj)
    print(f"Wrote {PBXPROJ.relative_to(REPO)} ({len(swift_files)} swift files)")


if __name__ == "__main__":
    main()
