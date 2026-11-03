// Deterministic playback checks. This does not replace watching the animation.
const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const path = require('node:path');
const root = path.resolve(__dirname, '../..');
const base = path.join(root, 'assets_src/characters/drawn_animation/2026-11-03');
const html = fs.readFileSync(path.join(base, 'preview.html'), 'utf8');
const data = JSON.parse(html.match(/<script id="review-data"[^>]*>([\s\S]*?)<\/script>/)[1]);
const source = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)].at(-1)[1];
const elements = new Map();
let renderNext=null, draws=0;
function element() { return {textContent:'', value:'', checked:false, children:[], dataset:{},
  classList:{toggle(){}}, append(e){this.children.push(e)}, replaceChildren(){this.children=[]},
  getContext(){return {canvas:this,setTransform(){},fillRect(){},drawImage(image,...args){
    assert.ok(image.complete && image.naturalWidth>0);
    if(args.length===8){assert.ok(args[0]>=0 && args[0]+args[2]<=image.naturalWidth);}
    draws++;
  }}}, click(){this.onclick?.()}}; }
function get(id) {if (!elements.has(id)) elements.set(id, element()); return elements.get(id);}
get('review-data').textContent = JSON.stringify(data);
const sandbox = {document:{getElementById:get, createElement:element, addEventListener(){}},
  Image:class {complete=false; naturalWidth=0;
    set src(value){const header=fs.readFileSync(path.join(base,value));
      this.naturalWidth=header.readUInt32BE(16);this.naturalHeight=header.readUInt32BE(20);this.complete=true;}
  }, requestAnimationFrame(fn){renderNext=fn}, window:{}};
vm.runInNewContext(source, sandbox, {filename:'drawn_animation_player.html'});
const player = sandbox.window.animationReview;
let checks=0;
for (const [pi,p] of data.profiles.entries()) {
  get('profile').onchange({target:{value:String(pi)}});
  assert.equal(player.state().profile,p.id); checks++;
  for(const [vi,view] of p.views.entries()){
  get('direction').onchange({target:{value:String(vi)}});
  assert.equal(player.state().view,view.id); checks++;
  player.select('attack');
  get('direction').onchange({target:{value:String((vi+1)%p.views.length)}});
  assert.equal(player.state().clip,'attack');checks++;
  get('direction').onchange({target:{value:String(vi)}});
  for (const clip of view.clips) {
    player.select(clip.id);
    assert.equal(player.state().frame,0);
    player.advance(clip.durations[0]);
    assert.equal(player.state().frame,Math.min(1,clip.frames-1));
    player.select(clip.id);
    player.advance(clip.durations.reduce((a,b)=>a+b,0));
    assert.equal(player.state().frame,clip.loop?0:clip.frames-1);
    assert.equal(player.state().playing,clip.loop);
    player.step(1);
    assert.equal(player.state().playing,false);
    assert.equal(player.state().frame,clip.loop?1:0);
    get('restart').click();
    assert.equal(player.state().frame,0);
    assert.equal(player.state().playing,true);
    renderNext(0);renderNext(16);
    assert.equal(player.state().loaded,true);
    assert.equal(get('error').textContent,'');
    checks+=9;
  }
  }
}
get('tour').click();
assert.equal(player.state().tour,true);
for(let i=0;i<80;i++)player.advance(100);
assert.notEqual(player.state().clip,data.profiles.at(-1).views.at(-1).clips[0].id);
assert.ok(draws>0);
checks+=2;
get('profile').onchange({target:{value:'0'}});
get('direction').onchange({target:{value:'0'}});
player.select('attack_alt');
const north=data.profiles[0].views.findIndex(v=>v.id==='north');
get('direction').onchange({target:{value:String(north)}});
assert.equal(player.state().clip,data.profiles[0].views[north].clips.some(c=>c.id==='attack_alt')?'attack_alt':'attack');checks++;
const result={status:'PASS',checks,profiles:data.profiles.length,canvas_draw_calls:draws,
  browser_render_check:'NOT_RUN: browser access host unavailable',continuous_motion_reviewed:false};
fs.writeFileSync(path.join(base,'player_logic_verification.json'),JSON.stringify(result,null,2)+'\n');
console.log('DRAWN_PLAYER_LOGIC_PASS',checks,'checks');
