from pathlib import Path
from PIL import Image
import json, shutil
root = Path(__file__).resolve().parents[1]
assets = root / 'Reach' / 'Assets.xcassets'
assets.mkdir(parents=True, exist_ok=True)
(assets/'Contents.json').write_text(json.dumps({'info':{'author':'xcode','version':1}}))
generated = Path(r'C:\Users\khiza\.codex\generated_images\01a12e9b-f7d0-73a2-aac5-c81470a64fdd')
hand = generated/'exec-7a8477b1-4658-4d5d-bf1f-765c24420b98.png'
atlas = generated/'exec-e9fb6587-9856-4641-a5f7-e01e20e059b5.png'
originals = root/'artwork'; originals.mkdir(exist_ok=True)
shutil.copy2(hand, originals/'hand-original.png'); shutil.copy2(atlas, originals/'ink-atlas-original.png')
def image_set(name, image):
    target=assets/(name+'.imageset');target.mkdir(exist_ok=True)
    image.save(target/'ink.png')
    (target/'Contents.json').write_text(json.dumps({'images':[{'filename':'ink.png','idiom':'universal'}],'info':{'author':'xcode','version':1}}))
image_set('hand',Image.open(hand).convert('RGB'))
img=Image.open(atlas).convert('RGB'); w,h=img.size
for name,box in [('skull',(0,0,w//2,h//2)),('eye',(w//2,0,w,h//2)),('shield',(0,h//2,w//2,h)),('sword',(w//2,h//2,w,h))]: image_set(name,img.crop(box))
icon=assets/'AppIcon.appiconset'; icon.mkdir(exist_ok=True)
entries=[]
for idiom,sizes in [('iphone',[(20,[2,3]),(29,[2,3]),(40,[2,3]),(60,[2,3])]),('ipad',[(20,[1,2]),(29,[1,2]),(40,[1,2]),(76,[1,2]),(83.5,[2])]),('ios-marketing',[(1024,[1])])]:
    for size,scales in sizes:
        for scale in scales:
            filename=f'{idiom}-{size}-{scale}.png';Image.open(hand).convert('RGB').resize((int(size*scale),int(size*scale)),Image.Resampling.LANCZOS).save(icon/filename)
            entries.append({'idiom':idiom,'size':f'{size}x{size}','scale':f'{scale}x','filename':filename})
(icon/'Contents.json').write_text(json.dumps({'images':entries,'info':{'author':'xcode','version':1}}))
print('Packaged hand icon and four ink illustrations into iOS asset catalog')
