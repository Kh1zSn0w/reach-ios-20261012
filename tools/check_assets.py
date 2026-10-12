import struct, json, re
from pathlib import Path
root=Path(__file__).resolve().parents[1]
for p in (root/'Reach'/'Fonts').glob('*.ttf'):
    data=p.read_bytes(); count=struct.unpack_from('>H',data,4)[0]
    for i in range(count):
        tag,checksum,offset,length=struct.unpack_from('>4sIII',data,12+16*i)
        if tag==b'name':
            version,records,strings=struct.unpack_from('>HHH',data,offset)
            names={}
            for j in range(records):
                platform,encoding,language,name,length,start=struct.unpack_from('>HHHHHH',data,offset+6+12*j)
                if name in (1,6) and platform in (0,3): names[name]=data[offset+strings+start:offset+strings+start+length].decode('utf-16-be')
            print(p.name,names)
quote_file=(root/'Reach'/'QuoteLibrary.swift').read_text(encoding='utf-8')
groups=re.findall(r'\("[^"\n]+", """\n(.*?)\n    """\)',quote_file,re.S)
print('Original quotes:',sum(len(g.splitlines()) for g in groups))
for catalog in (root/'Reach'/'Assets.xcassets').glob('*/Contents.json'):
    for item in json.loads(catalog.read_text())['images']:
        assert (catalog.parent/item['filename']).exists()
print('Asset catalogs complete')
