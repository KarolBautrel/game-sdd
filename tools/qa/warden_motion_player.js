/* Local file-safe player. No fetch/server/CDN, no native desktop input. */
"use strict";
const data = JSON.parse(document.getElementById("motion-data").textContent);
const FPS = data.fps;
let playing = true, speed = 1, view = "three_quarter", loaded = false, requestId = 0;
let lastTick = null, drawnFrames = 0, errors = [];
const cards = data.clips.map(clip => {
  const el = document.createElement("article"); el.className = "card";
  el.innerHTML = `<div class="card-top"><div><h2>${clip.title}</h2><small>${clip.subtitle}</small></div><span class="number">${clip.number}</span></div><div class="screen"><canvas width="384" height="384" aria-label="${clip.title}: zapętlona animacja"></canvas></div><div class="foot"><input class="timeline" aria-label="Klatka: ${clip.title}" type="range" min="0" max="${clip.frames-1}" value="0"><div class="readout"><span class="frame"></span><span>${(clip.frames/FPS).toFixed(2)} s</span></div><p class="caption">${clip.note}</p></div>`;
  document.getElementById("gallery").append(el);
  const card = {clip, el, canvas:el.querySelector("canvas"), slider:el.querySelector("input"), clock:0, images:[], frame:0};
  card.context = card.canvas.getContext("2d");
  card.slider.addEventListener("input", () => { setPlaying(false); card.clock = Number(card.slider.value)/FPS; draw(card); });
  return card;
});

function setPlaying(value) {
  playing = value; lastTick = null;
  document.getElementById("play").textContent = playing ? "Pauza" : "Odtwórz";
  document.getElementById("play").setAttribute("aria-label", playing ? "Wstrzymaj animacje" : "Odtwórz animacje");
}

async function loadView(next) {
  const ticket = ++requestId; loaded = false; lastTick = null;
  document.getElementById("status").textContent = "Wczytywanie klatek…";
  document.querySelectorAll("[data-view]").forEach(b => b.setAttribute("aria-pressed", String(b.dataset.view === next)));
  try {
    const sequences = await Promise.all(cards.map(async card => Promise.all(Array.from({length:card.clip.frames}, (_,i) => new Promise((resolve,reject) => {
      const im = new Image(); im.onload = () => resolve(im);
      im.onerror = () => reject(new Error(`${card.clip.id}/${next}/${i}`));
      im.src = `renders/${card.clip.id}/${next}/${String(i).padStart(3,"0")}.png`;
    })))));
    if (ticket !== requestId) return;
    view = next; cards.forEach((card,i) => {card.images = sequences[i]; draw(card);});
    loaded = true;
    document.getElementById("status").textContent = "Gotowe · 24 kl./s · 100 px/m";
  } catch(error) {
    errors.push(error.message); document.getElementById("status").textContent = `Brak klatki: ${error.message}`;
  }
}

function project(point, travel, yaw) {
  const x = point[0], y = point[1] + travel, z = point[2] - 1;
  const a = yaw*Math.PI/180, e = 18*Math.PI/180;
  return [192+100*(Math.cos(a)*x+Math.sin(a)*y),192-100*(-Math.sin(a)*Math.sin(e)*x+Math.cos(a)*Math.sin(e)*y+Math.cos(e)*z)];
}

function ground(ctx,card,f) {
  const yaw = data.views[view], travel = card.clip.id === "Walk" ? .64*f/card.clip.frames : 0;
  ctx.strokeStyle = "rgba(153,170,169,.085)"; ctx.lineWidth = 1;
  for(let i=-24;i<=24;i++) {
    const v = i*.32;
    for(const line of [[[-8,v,.008],[8,v,.008]],[[v,-8,.008],[v,8,.008]]]) {
      const a = project(line[0],travel,yaw),b = project(line[1],travel,yaw);
      ctx.beginPath();ctx.moveTo(...a);ctx.lineTo(...b);ctx.stroke();
    }
  }
  for(const side of ["L","R"]) {
    const foot = card.clip.feet[side][f], p = project([foot.center[0],foot.center[1],.008],travel,yaw);
    const opacity = .34*Math.exp(-Math.max(0,foot.minimum_z-.008)*22);
    ctx.fillStyle = `rgba(0,0,0,${opacity})`;ctx.beginPath();ctx.ellipse(p[0],p[1],9,3.1,0,0,Math.PI*2);ctx.fill();
  }
}

function draw(card) {
  const f = Math.floor(card.clock*FPS+1e-7)%card.clip.frames;
  card.frame = f; const ctx = card.context; ctx.clearRect(0,0,384,384);
  if(document.getElementById("ground").checked) ground(ctx,card,f);
  if(card.images[f]) {ctx.imageSmoothingEnabled = false;ctx.drawImage(card.images[f],0,0);}
  card.slider.value = String(f); card.el.querySelector(".frame").textContent = `KLATKA ${String(f+1).padStart(2,"0")} / ${card.clip.frames}`;
  card.canvas.dataset.frame = String(f); drawnFrames++;
}

function tick(now) {
  if(loaded && playing) {
    const dt = lastTick === null ? 0 : Math.min(.1,(now-lastTick)/1000);
    cards.forEach(card => {card.clock = (card.clock+dt*speed)%(card.clip.frames/FPS);draw(card);});
  }
  lastTick = now; requestAnimationFrame(tick);
}

function step() {setPlaying(false);cards.forEach(card => {card.clock = ((Math.floor(card.clock*FPS+1e-7)+1)%card.clip.frames)/FPS;draw(card);});}
document.getElementById("play").addEventListener("click",()=>setPlaying(!playing));
document.getElementById("step").addEventListener("click",step);
document.getElementById("speed").addEventListener("change",e=>{speed=Number(e.target.value);});
document.getElementById("zoom").addEventListener("click",e=>{const on=document.body.classList.toggle("zoom");e.currentTarget.setAttribute("aria-pressed",String(on));});
document.getElementById("ground").addEventListener("change",()=>cards.forEach(draw));
document.querySelectorAll("[data-view]").forEach(b=>b.addEventListener("click",()=>loadView(b.dataset.view)));
document.addEventListener("keydown",e=>{
  if(["INPUT","SELECT","BUTTON"].includes(e.target.tagName))return;
  if(e.code==="Space"){e.preventDefault();setPlaying(!playing);}
  if(e.code==="ArrowRight"){e.preventDefault();step();}
});
Object.defineProperty(window,"wardenPreview",{get:()=>({fps:FPS,playing,speed,view,loaded,drawnFrames,errors:errors.slice(),frames:cards.map(c=>({clip:c.clip.id,frame:c.frame,images:c.images.length}))})});
loadView(view);requestAnimationFrame(tick);
