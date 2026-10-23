#!/usr/bin/env python3
"""Rebuild the dependency-free Xcode project. Python 3 standard library only."""
from pathlib import Path
import hashlib, json
from xml.etree import ElementTree as ET
ROOT = Path(__file__).resolve().parents[1]
objects = {}
def uid(s): return hashlib.sha256(s.encode()).hexdigest()[:24].upper()
def obj(key, isa, **fields):
    ident=uid(key); objects[ident]={'isa':isa,**fields}; return ident

def configs(key, settings):
    ids=[]
    for mode in ['Debug','Release']:
        build=dict(settings)
        build.update({'SWIFT_OPTIMIZATION_LEVEL':'-Onone' if mode=='Debug' else '-O','DEBUG_INFORMATION_FORMAT':'dwarf' if mode=='Debug' else 'dwarf-with-dsym'})
        if mode=='Debug': build['SWIFT_ACTIVE_COMPILATION_CONDITIONS']=build.get('SWIFT_ACTIVE_COMPILATION_CONDITIONS','')+' DEBUG'
        ids.append(obj(key+mode,'XCBuildConfiguration',name=mode,buildSettings=build))
    return obj(key+'configs','XCConfigurationList',buildConfigurations=ids,defaultConfigurationIsVisible=0,defaultConfigurationName='Release')

names=['MathGate','MathGatePractice']
folders={'MathGate':'App','MathGatePractice':'App','MathGateMonitor':'Monitor','MathGateShield':'Shield','MathGateAction':'Action'}
source_sets={
'MathGate':['Core/Arithmetic.swift','Core/CompletionPass.swift','App/ShortcutActions.swift','App/MathGateApp.swift','App/ContentView.swift','App/Preferences.swift','App/SettingsView.swift','App/ChallengeView.swift'],
'MathGatePractice':['Core/Arithmetic.swift','Core/CompletionPass.swift','App/ShortcutActions.swift','App/MathGateApp.swift','App/ContentView.swift','App/Preferences.swift','App/SettingsView.swift','App/ChallengeView.swift'],
'MathGateMonitor':['Monitor/ActivityMonitor.swift'],
'MathGateShield':['Shield/ShieldConfigurationExtension.swift'],
'MathGateAction':['Action/ShieldActionExtension.swift']}
refs={}
for f in sorted(ROOT.rglob('*')):
    if not f.is_file() or '.xcodeproj' in str(f) or '.git' in f.parts: continue
    rel=f.relative_to(ROOT).as_posix()
    types={'.swift':'sourcecode.swift','.plist':'text.plist.xml','.entitlements':'text.plist.entitlements','.md':'net.daringfireball.markdown','.py':'text.script.python'}
    refs[rel]=obj('file:'+rel,'PBXFileReference',lastKnownFileType=types.get(f.suffix,'text'),path=rel,sourceTree='<group>')
products=[]
for name in names:
    ext='app' if name in names[:2] else 'appex'
    products.append(obj('product:'+name,'PBXFileReference',explicitFileType='wrapper.application' if ext=='app' else 'wrapper.app-extension',includeInIndex=0,path=name+'.'+ext,sourceTree='BUILT_PRODUCTS_DIR'))
product_group=obj('products','PBXGroup',children=products,name='Products',sourceTree='<group>')
main_group=obj('main','PBXGroup',children=list(refs.values())+[product_group],sourceTree='<group>')
for index,name in enumerate(names):
    extension=index>=2; practice=name=='MathGatePractice'; folder=folders[name]
    files=[obj('build:'+name+f,'PBXBuildFile',fileRef=refs[f]) for f in source_sets[name]]
    phases=[obj(name+'sources','PBXSourcesBuildPhase',buildActionMask=2147483647,files=files,runOnlyForDeploymentPostprocessing=0),obj(name+'frameworks','PBXFrameworksBuildPhase',buildActionMask=2147483647,files=[],runOnlyForDeploymentPostprocessing=0),obj(name+'resources','PBXResourcesBuildPhase',buildActionMask=2147483647,files=[],runOnlyForDeploymentPostprocessing=0)]
    dependencies=[]
    if False: # Screen Time targets are archived, not built or embedded.
        embed=[]
        for child in names[2:]:
            proxy=obj(child+'proxy','PBXContainerItemProxy',containerPortal=uid('project'),proxyType=1,remoteGlobalIDString=uid('target:'+child),remoteInfo=child)
            dependencies.append(obj(child+'dependency','PBXTargetDependency',target=uid('target:'+child),targetProxy=proxy))
            embed.append(obj(child+'embed','PBXBuildFile',fileRef=uid('product:'+child),settings={'ATTRIBUTES':['RemoveHeadersOnCopy']}))
        phases.append(obj('embed','PBXCopyFilesBuildPhase',buildActionMask=2147483647,dstPath='',dstSubfolderSpec=13,files=embed,name='Embed App Extensions',runOnlyForDeploymentPostprocessing=0))
    suffix={'MathGate':'','MathGatePractice':'.practice','MathGateMonitor':'.monitor','MathGateShield':'.shield','MathGateAction':'.action'}[name]
    settings={'PRODUCT_NAME':'$(TARGET_NAME)','PRODUCT_BUNDLE_IDENTIFIER':'com.shivanpoudel.mathgate'+suffix,'SWIFT_VERSION':'5.0','CODE_SIGN_STYLE':'Automatic','TARGETED_DEVICE_FAMILY':'1','SDKROOT':'iphoneos','SUPPORTED_PLATFORMS':'iphoneos iphonesimulator','IPHONEOS_DEPLOYMENT_TARGET':'17.0','MARKETING_VERSION':'1.0','CURRENT_PROJECT_VERSION':'1','LD_RUNPATH_SEARCH_PATHS':['$(inherited)','@executable_path/Frameworks']}
    if practice: settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS']='PRACTICE'

    if extension:
        settings.update({'INFOPLIST_FILE':folder+'/Info.plist','APPLICATION_EXTENSION_API_ONLY':'YES','SKIP_INSTALL':'YES','LD_RUNPATH_SEARCH_PATHS':['$(inherited)','@executable_path/Frameworks','@executable_path/../../Frameworks']})
    else:
        settings.update({'GENERATE_INFOPLIST_FILE':'YES','INFOPLIST_KEY_CFBundleDisplayName':'MathGate','INFOPLIST_KEY_UILaunchScreen_Generation':'YES','INFOPLIST_KEY_UIApplicationSceneManifest_Generation':'YES','INFOPLIST_KEY_UISupportedInterfaceOrientations':'UIInterfaceOrientationPortrait'})
    obj('target:'+name,'PBXNativeTarget',buildConfigurationList=configs(name,settings),buildPhases=phases,buildRules=[],dependencies=dependencies,name=name,productName=name,productReference=products[index],productType='com.apple.product-type.app-extension' if extension else 'com.apple.product-type.application')
obj('project','PBXProject',attributes={'LastUpgradeCheck':'2600','BuildIndependentTargetsInParallel':'YES','TargetAttributes':{uid('target:'+n):{'CreatedOnToolsVersion':'26.0','ProvisioningStyle':'Automatic'} for n in names}},buildConfigurationList=configs('project',{'CLANG_ENABLE_MODULES':'YES','SWIFT_VERSION':'5.0','SDKROOT':'iphoneos'}),compatibilityVersion='Xcode 14.0',developmentRegion='en',hasScannedForEncodings=0,knownRegions=['en','Base'],mainGroup=main_group,productRefGroup=product_group,projectDirPath='',projectRoot='',targets=[uid('target:'+n) for n in names])
def encode(value,level=0):
    if isinstance(value,dict): return '{\n'+''.join('\t'*(level+1)+json.dumps(str(k))+' = '+encode(v,level+1)+';\n' for k,v in value.items())+'\t'*level+'}'
    if isinstance(value,list): return '(\n'+''.join('\t'*(level+1)+encode(v,level+1)+',\n' for v in value)+'\t'*level+')'
    if isinstance(value,int): return str(value)
    return json.dumps(value)
project=ROOT/'MathGate.xcodeproj'; project.mkdir(exist_ok=True)
(project/'project.pbxproj').write_text('// !$*UTF8*$!\n'+encode({'archiveVersion':1,'classes':{},'objectVersion':56,'objects':objects,'rootObject':uid('project')})+'\n')
schemes=project/'xcshareddata/xcschemes'; schemes.mkdir(parents=True,exist_ok=True)
for name in names[:2]:
    root=ET.Element('Scheme',LastUpgradeVersion='2600',version='1.3')
    action=ET.SubElement(root,'BuildAction',parallelizeBuildables='YES',buildImplicitDependencies='YES')
    entries=ET.SubElement(action,'BuildActionEntries')
    entry=ET.SubElement(entries,'BuildActionEntry',buildForTesting='YES',buildForRunning='YES',buildForProfiling='YES',buildForArchiving='YES',buildForAnalyzing='YES')
    ref={'BuildableIdentifier':'primary','BlueprintIdentifier':uid('target:'+name),'BuildableName':name+'.app','BlueprintName':name,'ReferencedContainer':'container:MathGate.xcodeproj'}
    ET.SubElement(entry,'BuildableReference',ref)
    ET.SubElement(root,'TestAction',buildConfiguration='Debug',selectedDebuggerIdentifier='Xcode.DebuggerFoundation.Debugger.LLDB',selectedLauncherIdentifier='Xcode.IDEFoundation.Launcher.LLDB',shouldUseLaunchSchemeArgsEnv='YES')
    launch=ET.SubElement(root,'LaunchAction',buildConfiguration='Debug',selectedDebuggerIdentifier='Xcode.DebuggerFoundation.Debugger.LLDB',selectedLauncherIdentifier='Xcode.IDEFoundation.Launcher.LLDB',launchStyle='0',useCustomWorkingDirectory='NO',ignoresPersistentStateOnLaunch='NO',debugDocumentVersioning='YES',debugServiceExtension='internal',allowLocationSimulation='YES')
    ET.SubElement(ET.SubElement(launch,'BuildableProductRunnable',runnableDebuggingMode='0'),'BuildableReference',ref)
    profile=ET.SubElement(root,'ProfileAction',buildConfiguration='Release',shouldUseLaunchSchemeArgsEnv='YES',savedToolIdentifier='',useCustomWorkingDirectory='NO',debugDocumentVersioning='YES')
    ET.SubElement(ET.SubElement(profile,'BuildableProductRunnable',runnableDebuggingMode='0'),'BuildableReference',ref)
    ET.SubElement(root,'AnalyzeAction',buildConfiguration='Debug')
    ET.SubElement(root,'ArchiveAction',buildConfiguration='Release',revealArchiveInOrganizer='YES')
    ET.indent(root)
    ET.ElementTree(root).write(schemes/(name+'.xcscheme'),encoding='utf-8',xml_declaration=True)
print('Generated MathGate.xcodeproj: both schemes are entitlement-free timed practice.')
