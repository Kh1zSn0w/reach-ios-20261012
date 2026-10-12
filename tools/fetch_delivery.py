"""Fetch only delivery files and screenshots, skipping the bulky raw xcresult bundle."""
import io, json, os, pathlib, subprocess, sys, urllib.request, zipfile
ROOT=pathlib.Path(__file__).resolve().parents[1]
REPO='Kh1zSn0w/reach-ios-20261012'
p=subprocess.run(['git','credential','fill'],input='protocol=https\nhost=github.com\nusername=Kh1zSn0w\n\n',text=True,capture_output=True,check=True,env=dict(os.environ,GCM_INTERACTIVE='Never',GIT_TERMINAL_PROMPT='0'),creationflags=0x08000000)
token=dict(line.split('=',1) for line in p.stdout.splitlines() if '=' in line)['password']
headers={'Authorization':'Bearer '+token,'Accept':'application/vnd.github+json','User-Agent':'REACH-builder'}
run=sys.argv[1]
with urllib.request.urlopen(urllib.request.Request('https://api.github.com/repos/'+REPO+'/actions/runs/'+run+'/artifacts',headers=headers),timeout=30) as r: artifacts=json.load(r)['artifacts']
class Redirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        result=super().redirect_request(req,fp,code,msg,headers,newurl)
        if result: result.remove_header('Authorization')
        return result
class RemoteZip(io.RawIOBase):
    def __init__(self,url,length): self.url=url; self.length=length; self.position=0
    def seekable(self): return True
    def readable(self): return True
    def tell(self): return self.position
    def seek(self,offset,whence=0):
        self.position=offset if whence==0 else self.position+offset if whence==1 else self.length+offset
        return self.position
    def read(self,size=-1):
        if size<0: size=self.length-self.position
        size=min(size,self.length-self.position)
        if size<=0: return b''
        req=urllib.request.Request(self.url,headers={'Range':f'bytes={self.position}-{self.position+size-1}','User-Agent':'REACH-builder'})
        with urllib.request.urlopen(req,timeout=45) as response:
            if response.status!=206: raise RuntimeError('Artifact host did not honor byte ranges')
            result=response.read()
        self.position+=len(result); return result
for artifact in artifacts:
    req=urllib.request.Request(artifact['archive_download_url'],headers=headers)
    with urllib.request.build_opener(Redirect).open(req,timeout=30) as response:
        url=response.geturl(); length=int(response.headers['Content-Length'])
    target=ROOT/'artifacts'/run/artifact['name']; target.mkdir(parents=True,exist_ok=True)
    with zipfile.ZipFile(RemoteZip(url,length)) as archive:
        chosen=[n for n in archive.namelist() if not n.endswith('/') and (n in ['output/REACH-1.0.ipa','output/SHA256.txt','output/core-tests.txt','output/REACH-preview.png','build.log','uitest.log','output/screenshots/manifest.json'] or n.startswith('output/screenshots/') and n.endswith('.png'))]
        print(f'Fetching {len(chosen)} delivery files; skipping raw simulator result bundle',flush=True)
        for name in chosen:
            path=(target/name).resolve()
            assert path.is_relative_to(target.resolve())
            path.parent.mkdir(parents=True,exist_ok=True); path.write_bytes(archive.read(name))
            print(f'{name}: {path.stat().st_size:,} bytes',flush=True)
    print(str(target),flush=True)
