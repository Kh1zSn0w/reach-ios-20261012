from pathlib import Path
import hashlib, json, plistlib, shutil, struct, zipfile, sys
root=Path(__file__).resolve().parents[1]
source=root/'artifacts'/sys.argv[1]/'REACH-delivery'/'output'/'REACH-1.1.ipa'
digest=hashlib.sha256(source.read_bytes()).hexdigest()
expected=(source.parent/'SHA256.txt').read_text().split()[0]
assert digest==expected,'Artifact checksum mismatch'
with zipfile.ZipFile(source) as ipa:
    assert ipa.testzip() is None,'IPA CRC failure'
    info=plistlib.loads(ipa.read('Payload/Reach.app/Info.plist'))
    assert info['CFBundleIdentifier']=='app.reach.personal'
    assert info['CFBundleShortVersionString']=='1.1'
    assert info['MinimumOSVersion']=='15.0'
    executable=ipa.read('Payload/Reach.app/'+info['CFBundleExecutable'])
    magic,cpu=struct.unpack_from('<II',executable)
    assert magic==0xfeedfacf and cpu==0x0100000c,'IPA must contain an arm64 Mach-O'
    names=ipa.namelist()
    assert any(n.endswith('/Assets.car') for n in names),'Compiled artwork missing'
    assert any(n.endswith('/BebasNeue-Regular.ttf') for n in names),'English font missing'
    assert any(n.endswith('/ReemKufi[wght].ttf') for n in names),'Arabic font missing'
    assert info['NSCameraUsageDescription'],'Camera permission explanation missing'
target=Path.home()/'Downloads'/'REACH-1.1.ipa'
if target.exists() and hashlib.sha256(target.read_bytes()).hexdigest()!=digest:
    target=target.with_name('REACH-1.1-'+digest[:8]+'.ipa')
shutil.copy2(source,target)
assert hashlib.sha256(target.read_bytes()).hexdigest()==digest
report={'file':str(target),'size_bytes':target.stat().st_size,'sha256':digest,'bundle_id':info['CFBundleIdentifier'],'version':info['CFBundleShortVersionString'],'minimum_ios':info['MinimumOSVersion'],'architecture':'arm64','signing':'unsigned, ready for a sideloading signer','installed_on_phone':False}
(target.parent/(target.stem+'-verification.json')).write_text(json.dumps(report,indent=2))
print(json.dumps(report,indent=2))
