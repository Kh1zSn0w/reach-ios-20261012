import json, pathlib, shutil
folder=pathlib.Path('output/screenshots')
manifest=json.loads((folder/'manifest.json').read_text())
def records(value):
    if isinstance(value,dict):
        yield value
        for item in value.values(): yield from records(item)
    elif isinstance(value,list):
        for item in value: yield from records(item)
choice=None
for record in records(manifest):
    if any('01-Today' in str(v) for v in record.values() if isinstance(v,str)):
        for value in record.values():
            if isinstance(value,str) and value.endswith('.png') and (folder/value).exists(): choice=folder/value
if choice is None: choice=next(folder.glob('*.png'),None)
if choice:
    shutil.copy2(choice,'output/REACH-preview.png')
    print('Preview exported from actual UI test screenshot: '+choice.name)
