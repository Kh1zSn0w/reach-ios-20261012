import json, os, subprocess, urllib.request, urllib.error, sys, pathlib, zipfile, io
ROOT = pathlib.Path(__file__).resolve().parents[1]
REPO = 'Kh1zSn0w/reach-ios-20261012'
def token():
    p = subprocess.run(['git','credential','fill'], input='protocol=https\nhost=github.com\nusername=Kh1zSn0w\n\n',text=True,capture_output=True,check=True,env=dict(os.environ,GCM_INTERACTIVE='Never',GIT_TERMINAL_PROMPT='0'),creationflags=0x08000000)
    return dict(x.split('=',1) for x in p.stdout.splitlines() if '=' in x)['password']
def api(path, data=None, method=None):
    req=urllib.request.Request('https://api.github.com'+path,data=None if data is None else json.dumps(data).encode(),headers={'Authorization':'Bearer '+token(),'Accept':'application/vnd.github+json','User-Agent':'REACH-builder'},method=method)
    with urllib.request.urlopen(req,timeout=60) as r: return json.load(r)
command=sys.argv[1]
if command=='check':
    print(json.dumps({'account':api('/user')['login']}))
elif command=='public':
    r=api('/repos/'+REPO,{'private':False},'PATCH')
    print(json.dumps({'repo':r['full_name'],'private':r['private']}))
elif command=='create':
    try: r=api('/repos/'+REPO)
    except urllib.error.HTTPError as e:
        if e.code!=404: raise
        r=api('/user/repos',{'name':REPO.split('/')[1],'private':True,'description':'REACH private native iOS personal wellness app'})
    print(json.dumps({'repo':r['full_name'],'private':r['private']}))
elif command=='status':
    runs=api('/repos/'+REPO+'/actions/runs?per_page=3')['workflow_runs']
    print(json.dumps([{'id':r['id'],'status':r['status'],'conclusion':r['conclusion'],'url':r['html_url'],'sha':r['head_sha']} for r in runs]))
elif command=='logs':
    jobs=api('/repos/'+REPO+'/actions/runs/'+sys.argv[2]+'/jobs')['jobs']
    print(json.dumps([{'name':j['name'],'status':j['status'],'conclusion':j['conclusion'],'steps':j['steps']} for j in jobs]))
elif command=='diagnose':
    r=api('/repos/'+REPO+'/actions/runs/'+sys.argv[2])
    print(json.dumps({k:r.get(k) for k in ['status','conclusion','check_suite_url','run_attempt']}))
    suite=r['check_suite_url'].replace('https://api.github.com','')
    for check in api(suite+'/check-runs')['check_runs']:
        print(json.dumps({'name':check['name'],'output':check['output']}))
        if check['output'].get('annotations_count'):
            print(json.dumps(api('/repos/'+REPO+'/check-runs/'+str(check['id'])+'/annotations')))
elif command=='download':
    artifacts=api('/repos/'+REPO+'/actions/runs/'+sys.argv[2]+'/artifacts')['artifacts']
    for a in artifacts:
        req=urllib.request.Request(a['archive_download_url'],headers={'Authorization':'Bearer '+token(),'Accept':'application/vnd.github+json','User-Agent':'REACH-builder'})
        class Redirect(urllib.request.HTTPRedirectHandler):
            def redirect_request(self, req, fp, code, msg, headers, newurl):
                result=super().redirect_request(req,fp,code,msg,headers,newurl)
                if result: result.remove_header('Authorization')
                return result
        with urllib.request.build_opener(Redirect).open(req,timeout=90) as r: data=r.read()
        target=ROOT/'artifacts'/a['name'];target.mkdir(parents=True,exist_ok=True)
        with zipfile.ZipFile(io.BytesIO(data)) as z: z.extractall(target)
        print(str(target))
