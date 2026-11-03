// Browser composition evidence only. No Godot process, OS input or player saves.
// Node >=22 + installed Chrome. Run from the repository: node tools/qa/render_dungeon_ui_design.cjs
const fs=require('node:fs'),path=require('node:path'),{spawn}=require('node:child_process'),{pathToFileURL}=require('node:url');
const root=path.resolve(__dirname,'../..'),design=path.join(root,'docs/design/dungeon-ui');
const out=path.join(root,'artifacts/dungeon-ui-design',new Date().toISOString().replace(/[:.]/g,'-'));
fs.mkdirSync(out,{recursive:true});
const chrome=process.env.CHROME_EXE||'C:/Program Files/Google/Chrome/Application/chrome.exe';
const profile=path.join(out,'browser-profile');
const proc=spawn(chrome,['--headless=new','--remote-debugging-port=0',`--user-data-dir=${profile}`,'--no-first-run','--no-default-browser-check','--disable-background-networking','about:blank'],{windowsHide:true,stdio:'ignore'});
const pause=ms=>new Promise(r=>setTimeout(r,ms));
let socket,id=0;const pending=new Map(),errors=[],checks=[],captures=[];
function call(method,params={}){return new Promise((resolve,reject)=>{const key=++id;const timer=setTimeout(()=>{pending.delete(key);reject(Error('CDP timeout: '+method));},15000);pending.set(key,{resolve,reject,timer});socket.send(JSON.stringify({id:key,method,params}));});}
async function evaluate(expression){const r=await call('Runtime.evaluate',{expression,awaitPromise:true,returnByValue:true});if(r.exceptionDetails)throw Error(r.exceptionDetails.text+': '+JSON.stringify(r.exceptionDetails.exception));return r.result.value;}
function check(name,result){checks.push({name,pass:!!result});if(!result)throw Error('Design check failed: '+name);}
async function key(key,code,modifiers=0){await call('Input.dispatchKeyEvent',{type:'keyDown',key,code,modifiers});await call('Input.dispatchKeyEvent',{type:'keyUp',key,code,modifiers});await pause(30);}
async function capture(name,publish=false){const r=await call('Page.captureScreenshot',{format:'png',captureBeyondViewport:false});const target=path.join(out,name+'.png');fs.writeFileSync(target,Buffer.from(r.data,'base64'));if(publish)fs.copyFileSync(target,path.join(design,name+'.png'));captures.push(path.relative(root,target).replaceAll('\\','/'));}
async function settle(){await evaluate(`(async()=>{await document.fonts.ready;await Promise.all([...document.images].map(i=>i.complete?Promise.resolve():new Promise(r=>{i.onload=r;i.onerror=r;})));return true;})()`);await pause(160);}
async function layoutCheck(label){const r=await evaluate(`(()=>{const g=document.querySelector('.game').getBoundingClientRect();const badImages=[...document.images].filter(i=>!i.complete||!i.naturalWidth).map(i=>i.src);const h=document.querySelector('.header').getBoundingClientRect();const parts=[...document.querySelectorAll('.header>div,.header>nav')].map(e=>e.getBoundingClientRect());return {w:innerWidth,h:innerHeight,pageWidth:document.documentElement.scrollWidth,pageHeight:document.documentElement.scrollHeight,gameBottom:g.bottom,badImages,fonts:document.fonts.check('20px Source')&&document.fonts.check('24px Cinzel'),headerFits:parts.every(p=>p.right<=h.right+1&&p.left>=h.left-1)&&parts.every((p,i)=>!i||p.left>=parts[i-1].right-1)};})()`);check(label+' images/fonts',r.badImages.length===0&&r.fonts);check(label+' viewport fit',r.pageWidth<=r.w+1&&r.pageHeight<=r.h+1&&r.gameBottom<=r.h+1);check(label+' header fit',r.headerFits);return r;}
(async()=>{
 try{
  proc.on('error',e=>errors.push(e.message));
  const active=path.join(profile,'DevToolsActivePort');
  for(let n=0;!fs.existsSync(active)&&n<120;n++)await pause(100);
  if(!fs.existsSync(active))throw Error('Headless Chrome did not expose an endpoint');
  const port=fs.readFileSync(active,'utf8').split(/\r?\n/)[0];
  const targets=await(await fetch(`http://127.0.0.1:${port}/json/list`)).json();
  socket=new WebSocket(targets.find(t=>t.type==='page').webSocketDebuggerUrl);
  await new Promise((r,j)=>{socket.onopen=r;socket.onerror=j;});
  socket.onmessage=e=>{const r=JSON.parse(e.data);if(r.id){const q=pending.get(r.id);if(q){clearTimeout(q.timer);pending.delete(r.id);r.error?q.reject(Error(JSON.stringify(r.error))):q.resolve(r.result);}}else if(r.method==='Runtime.exceptionThrown')errors.push(JSON.stringify(r.params.exceptionDetails));};
  await call('Page.enable');await call('Runtime.enable');
  const url=pathToFileURL(path.join(design,'prototype.html')).href;
  for(const [w,h]of [[1920,1080],[1280,720],[2560,1440],[3440,1440],[3840,2160]]){
   await call('Emulation.setDeviceMetricsOverride',{width:w,height:h,deviceScaleFactor:1,mobile:false});
   await call('Page.navigate',{url});
   for(let n=0;n<80;n++){await pause(50);if(await evaluate('document.readyState==="complete"&&!!window.designStudy'))break;}
   await settle();await layoutCheck(w+'x'+h+' exploration');
   await capture('exploration-'+w+'x'+h,w===1920);
   await evaluate('window.designStudy.setMode("hazard")');await settle();
   check(w+'x'+h+' event fits',await evaluate(`(()=>{const m=document.querySelector('.decision').getBoundingClientRect();return m.top>=42&&m.bottom<=innerHeight&&m.left>=0&&m.right<=innerWidth;})()`));
   await capture('corridor-event-'+w+'x'+h,w===1920);
   await evaluate('window.designStudy.setMode("prepare")');await settle();
   check(w+'x'+h+' packing readable',await evaluate(`(()=>{const m=document.querySelector('.sheet').getBoundingClientRect();return m.top>=42&&m.bottom<=innerHeight&&document.querySelector('#budget').textContent==='7 / 7';})()`));
   await capture('packing-'+w+'x'+h,w===1920);
  }
  await call('Emulation.setDeviceMetricsOverride',{width:1920,height:1080,deviceScaleFactor:1,mobile:false});
  await evaluate('window.designStudy.setMode("lowlight")');await settle();
  check('low light named level and oil',await evaluate(`document.querySelector('#light-label').textContent==='Light 1 / 4'&&!document.querySelector('#lamp-action').hidden`));
  await capture('low-light-1920x1080',true);
  await evaluate('window.designStudy.setMode("hazard")');await settle();
  check('event background is inert',await evaluate(`[...document.querySelector('#game').children].filter(e=>e.id!=='modal').every(e=>e.inert)`));
  await key('Escape','Escape');check('forced choice cannot escape',await evaluate('!document.querySelector("#modal").hidden'));
  await evaluate('document.querySelector("#force-choice").focus()');await key('Tab','Tab');
  check('event focus loops',await evaluate('document.activeElement.id==="pick-choice"'));
  await evaluate('document.querySelector("#pick-choice").click()');
  check('resolving choice unlocks background',await evaluate('document.querySelector("#modal").hidden&&!document.querySelector(".header").inert'));
  await evaluate('window.designStudy.setMode("prepare")');await settle();
  check('packing cannot exceed capacity',await evaluate(`[...document.querySelectorAll('[data-plus]')].every(b=>b.disabled)`));
  await evaluate(`document.querySelector('[data-minus="0"]').click();document.querySelector('[data-minus="0"]').click();document.querySelector('[data-minus="1"]').click();document.querySelector('[data-plus="4"]').click()`);
  check('packing cost applied',await evaluate('document.querySelector("#budget").textContent==="6 / 7"'));
  await evaluate('window.designStudy.setMode("reward")');await settle();await capture('reward-1920x1080',true);
  await evaluate('document.querySelector("#claim").click()');check('reward becomes claimed receipt',await evaluate('window.designStudy.state.claimed&&document.querySelector("#claim").textContent==="Back to chart"'));
  await evaluate('document.querySelector("#claim").click()');
  await evaluate('window.designStudy.setMode("explore");document.querySelector("[data-open=journal]").focus();document.querySelector("[data-open=journal]").click()');await pause(60);await key('Escape','Escape');
  check('optional journal restores focus',await evaluate('document.querySelector("#modal").hidden&&document.activeElement.dataset.open==="journal"'));
  await evaluate('window.designStudy.selectRoom("armory")');check('non-adjacent locked destination cannot travel',await evaluate('document.querySelector("#travel").disabled'));
  await evaluate('window.designStudy.selectRoom("cache")');check('adjacent destination previews before travel',await evaluate('!document.querySelector("#travel").disabled&&document.querySelector("#modal").hidden'));
  check('no JavaScript runtime errors',errors.length===0);
  check('approved campaign frames used',await evaluate(`getComputedStyle(document.querySelector('.chart')).borderImageSource.includes('/campaign/frame_dark.png')&&getComputedStyle(document.querySelector('.primary')).borderImageSource.includes('/campaign/button.png')&&getComputedStyle(document.querySelector('.inspector')).borderImageSource.includes('/campaign/frame_paper.png')`));
  check('illustrated parchment map used',await evaluate(`getComputedStyle(document.querySelector('.map')).backgroundImage.includes('art/mine-chart.png')`));
  const report={status:'PASS',scope:'HTML design mockup only; not native Godot/runtime/physical-play acceptance',checks,captures,errors};
  fs.writeFileSync(path.join(out,'review.json'),JSON.stringify(report,null,2)+'\n');
  fs.copyFileSync(path.join(out,'review.json'),path.join(design,'browser-review.json'));
  console.log(JSON.stringify({status:report.status,checks:checks.length,output:path.relative(root,out)},null,2));
 }catch(e){fs.writeFileSync(path.join(out,'failure.json'),JSON.stringify({error:e.message,checks,errors},null,2));console.error(e.stack);process.exitCode=1;}
 finally{if(socket?.readyState===WebSocket.OPEN){try{await call('Browser.close');}catch{}socket.close();}if(proc.exitCode===null)proc.kill();}
})();
