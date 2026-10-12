from pathlib import Path
import urllib.request, urllib.parse
root=Path(__file__).resolve().parents[1]
target=root/'Reach'/'Fonts'; target.mkdir(exist_ok=True)
for family,name in [('bebasneue','BebasNeue-Regular.ttf'),('reemkufi','ReemKufi[wght].ttf')]:
    for remote,local in [(name,name),('OFL.txt',family+'-OFL.txt')]:
        url='https://raw.githubusercontent.com/google/fonts/main/ofl/'+family+'/'+urllib.parse.quote(remote)
        with urllib.request.urlopen(url,timeout=30) as response: (target/local).write_bytes(response.read())
    print('Bundled '+family+' font and license')
