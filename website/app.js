/* ===========================================================
   Box2Dxt site — interactive HyperCard "desktop"
   1) Mobile menu + copy buttons
   2) A reusable 2D physics world (factory) — crates + balls,
      drag/fling, used by the hero demo AND the Playground
   3) The Playground: a tiny xTalk interpreter that runs a
      friendly subset of b2k… commands against a live world
   4) Scroll-spy nav, scroll-reveal, smooth scrolling
   5) The floating HyperTalk Message Box
   Vanilla JS, no libraries. Degrades to a plain scroll page.
   =========================================================== */
(function () {
  "use strict";
  var INK = "#17140d";
  var reduceMotion = window.matchMedia && matchMedia("(prefers-reduced-motion: reduce)").matches;
  var COLORS = {
    orange: "#e8702a", blue: "#2f5fae", green: "#3f8f5b", red: "#d23b3b",
    purple: "#8a63d2", teal: "#2bb3a3", yellow: "#e8b53a", pink: "#d46aa6",
    brown: "#9c5a2c", gray: "#7c7468", grey: "#7c7468", black: "#2a2620",
    white: "#efe9dc", tan: "#e8a23a"
  };
  var CRATE_POOL = ["#e8702a", "#2f5fae", "#3f8f5b", "#d23b3b", "#e8a23a"];
  function normColor(c) {
    if (c == null || c === "") return null;
    c = ("" + c).toLowerCase().trim().replace(/^["']|["']$/g, "");
    if (COLORS[c]) return COLORS[c];
    if (/^#([0-9a-f]{3}|[0-9a-f]{6})$/.test(c)) return c;
    return null;
  }
  function num(x) { var n = typeof x === "number" ? x : parseFloat(x); return isNaN(n) ? 0 : n; }
  function clamp(v, a, b) { return Math.max(a, Math.min(b, v)); }

  /* ---------- Mobile menu ---------- */
  var toggle = document.getElementById("menuToggle");
  var links = document.getElementById("menuLinks");
  if (toggle && links) {
    toggle.addEventListener("click", function () {
      var open = links.classList.toggle("open");
      toggle.setAttribute("aria-expanded", open ? "true" : "false");
    });
    links.addEventListener("click", function (e) {
      if (e.target.tagName === "A") { links.classList.remove("open"); toggle.setAttribute("aria-expanded", "false"); }
    });
  }

  /* ---------- Copy buttons on every code block ---------- */
  [].forEach.call(document.querySelectorAll("pre"), function (pre) {
    if (pre.querySelector(".copy-btn")) return;
    var btn = document.createElement("button");
    btn.type = "button"; btn.className = "copy-btn"; btn.textContent = "copy";
    btn.setAttribute("aria-label", "Copy code to clipboard");
    btn.addEventListener("click", function () {
      var code = pre.querySelector("code");
      var text = code ? code.innerText : pre.innerText;
      var done = function () { btn.textContent = "copied!"; setTimeout(function () { btn.textContent = "copy"; }, 1400); };
      if (navigator.clipboard && navigator.clipboard.writeText) navigator.clipboard.writeText(text).then(done, done);
      else { try { var r = document.createRange(); r.selectNodeContents(code || pre); var s = getSelection(); s.removeAllRanges(); s.addRange(r); document.execCommand("copy"); s.removeAllRanges(); done(); } catch (e) { /* no-op */ } }
    });
    pre.appendChild(btn);
  });

  /* =========================================================
     A reusable physics world
     ========================================================= */
  function createWorld(canvas, opts) {
    opts = opts || {};
    var ctx = canvas.getContext("2d");
    var MAX = opts.max || 70;
    var GRAV = 1700, REST = 0.14, WALL_REST = 0.3, FRICTION = 0.18;
    var SLOP = 0.5, CORRECT = 0.8, ITER = 6, DT = 1 / 120, MAXV = 2600, MAXSPIN = 16;
    var W = 0, H = 0, dpr = 1, bodies = [], gravityOn = true;
    var held = null, heldInv = 0, pointer = { x: 0, y: 0, active: false };
    var running = false, last = 0, acc = 0;
    var rnd = function (a, b) { return a + Math.random() * (b - a); };

    function roundRect(x, y, w, h, r) {
      ctx.beginPath(); ctx.moveTo(x + r, y);
      ctx.arcTo(x + w, y, x + w, y + h, r); ctx.arcTo(x + w, y + h, x, y + h, r);
      ctx.arcTo(x, y + h, x, y, r); ctx.arcTo(x, y, x + w, y, r); ctx.closePath();
    }
    function resize() {
      var rect = canvas.getBoundingClientRect();
      W = Math.max(1, rect.width); H = Math.max(1, rect.height);
      dpr = Math.min(window.devicePixelRatio || 1, 2);
      canvas.width = Math.round(W * dpr); canvas.height = Math.round(H * dpr);
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      for (var i = 0; i < bodies.length; i++) {
        bodies[i].x = clamp(bodies[i].x, bodies[i].r, W - bodies[i].r);
        bodies[i].y = clamp(bodies[i].y, bodies[i].r, H - bodies[i].r);
      }
    }
    function add(b) { if (bodies.length >= MAX) bodies.shift(); bodies.push(b); return b; }
    function spawnBox(x, y, w, h, color) {
      w = clamp(num(w), 8, 300); h = clamp(num(h), 8, 300);
      var r = Math.max(6, Math.min(w, h) / 2 * 0.96);
      return add({ x: clamp(num(x), r, W - r), y: num(y), vx: 0, vy: 0, r: r, w: w, h: h,
        angle: rnd(-0.25, 0.25), spin: 0, shape: "crate",
        color: normColor(color) || CRATE_POOL[(Math.random() * CRATE_POOL.length) | 0], invMass: 1 / (r * r) });
    }
    function spawnBall(x, y, d, color) {
      var r = clamp(num(d) / 2, 6, 90);
      return add({ x: clamp(num(x), r, W - r), y: num(y), vx: 0, vy: 0, r: r, w: 2 * r, h: 2 * r,
        angle: rnd(-0.3, 0.3), spin: rnd(-2, 2), shape: "ball",
        color: normColor(color) || (Math.random() < 0.5 ? "#2a2620" : "#3a3530"), invMass: 1 / (r * r) });
    }
    function clear() { bodies = []; }
    function impulseAll(dx, dy) { for (var i = 0; i < bodies.length; i++) { bodies[i].vx += num(dx); bodies[i].vy += num(dy); } }
    function seed() {
      bodies = [];
      var n = W < 420 ? 9 : 12;
      for (var i = 0; i < n; i++) {
        if (Math.random() < 0.22) spawnBall(rnd(30, W - 30), rnd(-H, H * 0.3), rnd(30, 52));
        else spawnBox(rnd(30, W - 30), rnd(-H, H * 0.3), rnd(34, 52), rnd(34, 52));
      }
    }

    function step() {
      var i, j, b;
      for (i = 0; i < bodies.length; i++) {
        b = bodies[i]; b.angle += b.spin * DT; b.spin *= 0.992;
        if (b === held) continue;
        if (gravityOn) b.vy += GRAV * DT;
        b.x += b.vx * DT; b.y += b.vy * DT;
        var sp = Math.hypot(b.vx, b.vy); if (sp > MAXV) { b.vx *= MAXV / sp; b.vy *= MAXV / sp; }
        if (b.spin > MAXSPIN) b.spin = MAXSPIN; else if (b.spin < -MAXSPIN) b.spin = -MAXSPIN;
      }
      if (held) {
        var px = clamp(pointer.x, held.r, W - held.r), py = clamp(pointer.y, held.r, H - held.r);
        held.vx = (px - held.x) / DT; held.vy = (py - held.y) / DT; held.x = px; held.y = py;
      }
      for (var it = 0; it < ITER; it++) {
        for (i = 0; i < bodies.length; i++) for (j = i + 1; j < bodies.length; j++) {
          var a = bodies[i], c = bodies[j];
          var dx = c.x - a.x, dy = c.y - a.y, dist = Math.hypot(dx, dy), mn = a.r + c.r;
          if (dist >= mn || dist === 0) continue;
          var nx = dx / dist, ny = dy / dist, pen = mn - dist, im = a.invMass + c.invMass;
          var corr = (Math.max(pen - SLOP, 0) / im) * CORRECT;
          a.x -= nx * corr * a.invMass; a.y -= ny * corr * a.invMass;
          c.x += nx * corr * c.invMass; c.y += ny * corr * c.invMass;
          var rvx = c.vx - a.vx, rvy = c.vy - a.vy, vn = rvx * nx + rvy * ny;
          if (vn < 0) {
            var jn = -(1 + REST) * vn / im;
            a.vx -= jn * nx * a.invMass; a.vy -= jn * ny * a.invMass;
            c.vx += jn * nx * c.invMass; c.vy += jn * ny * c.invMass;
            var tx = -ny, ty = nx, vt = (c.vx - a.vx) * tx + (c.vy - a.vy) * ty, jt = -vt * FRICTION / im;
            a.vx -= jt * tx * a.invMass; a.vy -= jt * ty * a.invMass;
            c.vx += jt * tx * c.invMass; c.vy += jt * ty * c.invMass;
            var kick = vt * 0.03; a.spin -= kick; c.spin += kick;
          }
        }
        for (i = 0; i < bodies.length; i++) {
          b = bodies[i]; if (b === held) continue;
          if (b.x < b.r) { b.x = b.r; if (b.vx < 0) b.vx = -b.vx * WALL_REST; b.spin *= 0.8; }
          else if (b.x > W - b.r) { b.x = W - b.r; if (b.vx > 0) b.vx = -b.vx * WALL_REST; b.spin *= 0.8; }
          if (b.y < b.r) { b.y = b.r; if (b.vy < 0) b.vy = -b.vy * WALL_REST; }
          else if (b.y > H - b.r) { b.y = H - b.r; if (b.vy > 0) b.vy = -b.vy * WALL_REST; b.vx *= 0.985; b.spin = b.spin * 0.6 + (b.vx / b.r) * 0.4; }
        }
      }
    }
    function drawCrate(b) {
      var w = b.w, h = b.h, in1 = Math.min(w, h) * 0.13;
      roundRect(b.x - w / 2 + 3, b.y - h / 2 + 4, w, h, Math.min(w, h) * 0.16);
      ctx.fillStyle = "rgba(23,20,13,0.16)"; ctx.fill();
      ctx.save(); ctx.translate(b.x, b.y); ctx.rotate(b.angle);
      roundRect(-w / 2, -h / 2, w, h, Math.min(w, h) * 0.16);
      ctx.fillStyle = b.color; ctx.fill();
      ctx.lineWidth = 2.4; ctx.strokeStyle = INK; ctx.stroke();
      ctx.lineWidth = 2; ctx.strokeStyle = "rgba(23,20,13,0.8)";
      ctx.beginPath(); ctx.moveTo(-w / 2 + in1, -h / 2 + in1); ctx.lineTo(w / 2 - in1, h / 2 - in1);
      ctx.moveTo(w / 2 - in1, -h / 2 + in1); ctx.lineTo(-w / 2 + in1, h / 2 - in1); ctx.stroke();
      ctx.restore();
    }
    function drawBall(b) {
      ctx.beginPath(); ctx.arc(b.x + 2.5, b.y + 4, b.r, 0, 7); ctx.fillStyle = "rgba(23,20,13,0.16)"; ctx.fill();
      ctx.beginPath(); ctx.arc(b.x, b.y, b.r, 0, 7); ctx.fillStyle = b.color; ctx.fill();
      ctx.lineWidth = 2.4; ctx.strokeStyle = INK; ctx.stroke();
      ctx.save(); ctx.translate(b.x, b.y); ctx.rotate(b.angle);
      ctx.beginPath(); ctx.arc(-b.r * 0.34, -b.r * 0.34, b.r * 0.24, 0, 7); ctx.fillStyle = "rgba(255,255,255,0.5)"; ctx.fill();
      ctx.restore();
    }
    function draw() { ctx.clearRect(0, 0, W, H); for (var i = 0; i < bodies.length; i++) bodies[i].shape === "ball" ? drawBall(bodies[i]) : drawCrate(bodies[i]); }
    function frame(t) { if (!running) return; if (!last) last = t; acc += Math.min((t - last) / 1000, 0.05); last = t; var g = 0; while (acc >= DT && g < 8) { step(); acc -= DT; g++; } draw(); requestAnimationFrame(frame); }
    function start() { if (!running) { running = true; last = 0; requestAnimationFrame(frame); } }
    function stop() { running = false; }

    function pt(e) { var r = canvas.getBoundingClientRect(); return { x: (e.touches ? e.touches[0].clientX : e.clientX) - r.left, y: (e.touches ? e.touches[0].clientY : e.clientY) - r.top }; }
    function onDown(e) {
      var p = pt(e); pointer.x = p.x; pointer.y = p.y; pointer.active = true;
      if (opts.onInteract) opts.onInteract();
      var best = null, bd = Infinity;
      for (var i = 0; i < bodies.length; i++) { var b = bodies[i], d = Math.hypot(b.x - p.x, b.y - p.y); if (d <= b.r + 6 && d < bd) { best = b; bd = d; } }
      if (best) { held = best; heldInv = best.invMass; best.invMass = 0; } else if (opts.dropOnClick !== false) { spawnBox(p.x, p.y, rnd(34, 52), rnd(34, 52)); }
      e.preventDefault();
    }
    function onMove(e) { if (pointer.active) { var p = pt(e); pointer.x = p.x; pointer.y = p.y; e.preventDefault(); } }
    function onUp() { pointer.active = false; if (held) { held.invMass = heldInv; held.spin = clamp(-held.vx / held.r * 0.4, -MAXSPIN, MAXSPIN); held = null; } }
    canvas.addEventListener("mousedown", onDown);
    window.addEventListener("mousemove", onMove);
    window.addEventListener("mouseup", onUp);
    canvas.addEventListener("touchstart", onDown, { passive: false });
    canvas.addEventListener("touchmove", onMove, { passive: false });
    window.addEventListener("touchend", onUp);

    resize();
    if (opts.seed) seed();
    window.addEventListener("resize", resize);
    document.addEventListener("visibilitychange", function () { if (document.hidden) stop(); });
    if ("IntersectionObserver" in window) {
      new IntersectionObserver(function (en) { if (en[0].isIntersecting) start(); else stop(); }, { threshold: 0.02 }).observe(canvas);
    } else { start(); }

    return {
      start: start, stop: stop, spawnBox: spawnBox, spawnBall: spawnBall, clear: clear,
      impulseAll: impulseAll, gravity: function (on) { gravityOn = !!on; }, gravityOn: function () { return gravityOn; },
      reset: function () { opts.seed ? seed() : clear(); }, count: function () { return bodies.length; },
      w: function () { return W; }, h: function () { return H; }
    };
  }

  /* ---------- Hero demo world ---------- */
  var heroCanvas = document.getElementById("physics");
  if (heroCanvas && heroCanvas.getContext) {
    var heroHinted = false, heroHint = document.getElementById("demoHint");
    var hero = createWorld(heroCanvas, { max: 24, seed: true, onInteract: function () { if (!heroHinted && heroHint) { heroHinted = true; heroHint.style.transition = "opacity .4s"; heroHint.style.opacity = "0"; } } });
    var hr = document.getElementById("demoReset"), hg = document.getElementById("demoGravity");
    if (hr) hr.addEventListener("click", function () { hero.reset(); });
    if (hg) hg.addEventListener("click", function () { var on = !hero.gravityOn(); hero.gravity(on); hg.textContent = "GRAVITY: " + (on ? "ON" : "OFF"); if (!on) hero.impulseAll(0, -120); });
    setTimeout(function () { if (!heroHinted && heroHint) { heroHint.style.transition = "opacity .4s"; heroHint.style.opacity = "0"; } }, 6000);
  }

  /* =========================================================
     The Playground: a tiny xTalk interpreter
     ========================================================= */
  var pgCanvas = document.getElementById("pgCanvas");
  var pgRunner = null, pgWorld = null;
  if (pgCanvas && pgCanvas.getContext) {
    pgWorld = createWorld(pgCanvas, { max: 80, seed: false, dropOnClick: true });
    var pgCode = document.getElementById("pgCode");
    var pgOut = document.getElementById("pgOut");
    function setOut(s) { if (pgOut) pgOut.textContent = s; }

    pgRunner = (function (world) {
      var BUD = 0, outbox = [];
      function budget() { if (--BUD < 0) throw { pg: "script too long — stopped" }; }

      function tokenize(s) {
        var t = [], i = 0, n = s.length;
        while (i < n) {
          var c = s[i];
          if (c === " " || c === "\t") { i++; continue; }
          if (c === '"') { var j = i + 1, v = ""; while (j < n && s[j] !== '"') v += s[j++]; i = j + 1; t.push({ t: "str", v: v }); continue; }
          if (/[0-9]/.test(c) || (c === "." && /[0-9]/.test(s[i + 1] || ""))) { var num0 = ""; while (i < n && /[0-9.]/.test(s[i])) num0 += s[i++]; t.push({ t: "num", v: parseFloat(num0) }); continue; }
          if (/[A-Za-z_]/.test(c)) { var id = ""; while (i < n && /[A-Za-z0-9_]/.test(s[i])) id += s[i++]; t.push({ t: "id", v: id }); continue; }
          if ("+-*/&(),".indexOf(c) >= 0) { t.push({ t: "op", v: c }); i++; continue; }
          i++;
        }
        return t;
      }
      function str(x) { return x == null ? "" : "" + x; }
      function callFn(name, a) {
        switch (name) {
          case "random": return Math.floor(Math.random() * Math.max(1, num(a[0])));
          case "abs": return Math.abs(num(a[0]));
          case "round": return Math.round(num(a[0]));
          case "min": return Math.min(num(a[0]), num(a[1]));
          case "max": return Math.max(num(a[0]), num(a[1]));
          case "sqrt": return Math.sqrt(num(a[0]));
          case "sin": return Math.sin(num(a[0]));
          case "cos": return Math.cos(num(a[0]));
          default: return 0;
        }
      }
      function evalExpr(src, vars) {
        var tk = tokenize(src), p = 0;
        function peek() { return tk[p]; }
        function nextT() { return tk[p++]; }
        function expect(v) { var x = nextT(); if (!x || x.v !== v) throw { pg: "expected '" + v + "'" }; }
        function pExpr() { return pConcat(); }
        function pConcat() { var l = pAdd(); while (peek() && peek().v === "&") { nextT(); l = str(l) + str(pAdd()); } return l; }
        function pAdd() { var l = pMul(); while (peek() && (peek().v === "+" || peek().v === "-")) { var o = nextT().v; var r = pMul(); l = o === "+" ? num(l) + num(r) : num(l) - num(r); } return l; }
        function pMul() { var l = pUn(); while (peek() && (peek().v === "*" || peek().v === "/")) { var o = nextT().v; var r = pUn(); l = o === "*" ? num(l) * num(r) : num(l) / num(r); } return l; }
        function pUn() { if (peek() && peek().v === "-") { nextT(); return -num(pUn()); } return pAtom(); }
        function pAtom() {
          var x = nextT(); if (!x) throw { pg: "unexpected end" };
          if (x.t === "num") return x.v;
          if (x.t === "str") return x.v;
          if (x.v === "(") { var e = pExpr(); expect(")"); return e; }
          if (x.t === "id") {
            var nm = x.v.toLowerCase();
            if (peek() && peek().v === "(") { nextT(); var args = []; if (!(peek() && peek().v === ")")) { args.push(pExpr()); while (peek() && peek().v === ",") { nextT(); args.push(pExpr()); } } expect(")"); return callFn(nm, args); }
            if (nm === "true") return 1; if (nm === "false") return 0; if (nm === "pi") return Math.PI;
            return vars[nm] !== undefined ? vars[nm] : 0;
          }
          throw { pg: "bad expression" };
        }
        return pExpr();
      }
      function stripComment(s) { var q = false, i = 0; for (; i < s.length - 1; i++) { if (s[i] === '"') q = !q; else if (!q && s[i] === "-" && s[i + 1] === "-") return s.slice(0, i); } return s; }
      function splitArgs(s) { var out = [], d = 0, cur = "", q = false; for (var i = 0; i < s.length; i++) { var c = s[i]; if (c === '"') q = !q; if (!q && c === "(") d++; else if (!q && c === ")") d--; if (!q && c === "," && d === 0) { out.push(cur); cur = ""; } else cur += c; } if (cur.trim() !== "") out.push(cur); return out; }
      function evalArgs(rest, vars) { return splitArgs(rest).map(function (a) { return evalExpr(a, vars); }); }

      function execStmt(line, vars) {
        budget();
        var s = stripComment(line).trim(); if (s === "") return;
        var sp = s.indexOf(" "), cmd = (sp < 0 ? s : s.slice(0, sp)).toLowerCase(), rest = (sp < 0 ? "" : s.slice(sp + 1)).trim();
        var a;
        switch (cmd) {
          case "put": { var m = rest.match(/^(.*)\s+into\s+([A-Za-z_]\w*)\s*$/i); if (m) vars[m[2].toLowerCase()] = evalExpr(m[1], vars); else outbox.push(str(evalExpr(rest, vars))); break; }
          case "answer": outbox.push(str(evalExpr(rest, vars))); break;
          case "b2kspawnbox": case "b2kspawncapsule": a = evalArgs(rest, vars); world.spawnBox(a[0], a[1], a[2], a[3], a[4]); break;
          case "b2kspawnball": a = evalArgs(rest, vars); world.spawnBall(a[0], a[1], a[2], a[3]); break;
          case "b2kgravity": world.gravity(!/^(off|false|0|no)\b/i.test(rest.trim())); break;
          case "b2kclear": world.clear(); break;
          case "b2kimpulse": a = evalArgs(rest, vars); world.impulseAll(a[0] || 0, a[1] || 0); break;
          case "b2krain": { var nn = rest ? num(evalExpr(rest, vars)) : 10; nn = clamp(nn, 0, 40); for (var k = 0; k < nn; k++) world.spawnBall(20 + Math.random() * (world.w() - 40), 10, 18 + Math.random() * 22); break; }
          case "set": { var mg = rest.match(/^gravity\s+to\s+(.+)$/i); if (mg) world.gravity(num(evalExpr(mg[1], vars)) !== 0); break; }
          case "if": { var mi = rest.match(/^(.*?)\s+then\s+(.+)$/i); if (mi && evalCond(mi[1], vars)) execStmt(mi[2], vars); break; }
          case "wait": case "get": break;
          default: if (cmd.indexOf("b2k") !== 0) outbox.push('Don\'t understand "' + cmd + '"');
        }
      }
      function evalCond(c, vars) {
        var m = c.match(/(.*?)(>=|<=|<>|=|>|<|\bis\b)(.*)/i); if (!m) return num(evalExpr(c, vars)) !== 0;
        var l = evalExpr(m[1], vars), r = evalExpr(m[3], vars), op = m[2].toLowerCase();
        if (op === ">=") return num(l) >= num(r); if (op === "<=") return num(l) <= num(r);
        if (op === ">") return num(l) > num(r); if (op === "<") return num(l) < num(r);
        if (op === "<>") return str(l) !== str(r); return str(l) === str(r);
      }
      function execBlock(lines, vars) {
        var i = 0;
        while (i < lines.length) {
          budget();
          var s = stripComment(lines[i]).trim();
          if (s === "") { i++; continue; }
          var rep = s.match(/^repeat\b(.*)$/i);
          if (rep) {
            var depth = 1, j = i + 1, inner = [];
            for (; j < lines.length; j++) { var tt = lines[j].trim(); if (/^repeat\b/i.test(tt)) depth++; else if (/^end\s+repeat\b/i.test(tt)) { depth--; if (depth === 0) break; } if (depth > 0) inner.push(lines[j]); }
            runRepeat(rep[1].trim(), inner, vars); i = j + 1; continue;
          }
          if (/^end\s+repeat\b/i.test(s)) { i++; continue; }
          execStmt(s, vars); i++;
        }
      }
      function runRepeat(spec, inner, vars) {
        var mw = spec.match(/^with\s+([A-Za-z_]\w*)\s*=\s*(.+?)\s+to\s+(.+)$/i);
        if (mw) { var name = mw[1].toLowerCase(), a = Math.round(num(evalExpr(mw[2], vars))), b = Math.round(num(evalExpr(mw[3], vars))), c = 0; for (var v = a; v <= b; v++) { if (++c > 200) break; budget(); vars[name] = v; execBlock(inner, vars); } return; }
        var mn = spec.match(/^(?:for\s+)?(.+?)\s+times$/i) || (spec.trim() ? spec.match(/^(.+)$/) : null);
        var times = mn ? Math.round(num(evalExpr(mn[1], vars))) : 0;
        times = clamp(times, 0, 200);
        for (var k = 0; k < times; k++) { budget(); execBlock(inner, vars); }
      }
      function bodyFor(src, prefer) {
        var lines = src.replace(/\r\n/g, "\n").split("\n"), handlers = {}, order = [], cur = null, buf = [];
        for (var i = 0; i < lines.length; i++) {
          var t = lines[i].trim(), mOn = t.match(/^on\s+([A-Za-z_]\w*)/i), mEnd = t.match(/^end\s+([A-Za-z_]\w*)/i);
          if (cur === null && mOn) { cur = mOn[1].toLowerCase(); buf = []; order.push(cur); continue; }
          if (cur !== null && mEnd && mEnd[1].toLowerCase() === cur) { handlers[cur] = buf; cur = null; continue; }
          if (cur !== null) buf.push(lines[i]);
        }
        if (prefer && handlers[prefer.toLowerCase()]) return handlers[prefer.toLowerCase()];
        if (order.length) return handlers[order[0]];
        return lines.filter(function (l) { return !/^\s*(on|end)\s+\w+/i.test(l); });
      }
      function finish() {
        if (outbox.length) setOut(outbox.join("  ·  "));
        else setOut("ran · " + world.count() + " bodies");
      }
      return {
        run: function (src, prefer) { BUD = 4000; outbox = []; try { execBlock(bodyFor(src, prefer || "mouseUp"), {}); finish(); } catch (e) { setOut("⚠ " + (e && e.pg ? e.pg : "error")); } },
        exec1: function (line) { BUD = 4000; outbox = []; try { execStmt(line, {}); finish(); } catch (e) { setOut("⚠ " + (e && e.pg ? e.pg : "error")); } }
      };
    })(pgWorld);

    var PRESETS = {
      tower: "-- A stack of crates, then a ball on top.\non mouseUp\n  b2kClear\n  repeat with i = 1 to 6\n    b2kSpawnBox 230, 320 - i * 46, 78, 42, \"orange\"\n  end repeat\n  b2kSpawnBall 252, 20, 44, \"blue\"\nend mouseUp",
      rain: "-- Drop a shower of balls.\non mouseUp\n  repeat 14 times\n    b2kSpawnBall random(360) + 30, 10, random(26) + 18\n  end repeat\nend mouseUp",
      zerog: "-- Turn gravity off and fill the void.\non mouseUp\n  b2kClear\n  b2kGravity off\n  repeat 12 times\n    b2kSpawnBall random(360) + 30, random(280) + 20, 30, \"teal\"\n  end repeat\nend mouseUp",
      kick: "-- Spawn some crates, then kick them up.\non mouseUp\n  b2kClear\n  repeat 5 times\n    b2kSpawnBox random(300) + 60, 300, 50, 50, \"red\"\n  end repeat\n  b2kImpulse 0, -700\nend mouseUp",
      pyramid: "-- A pyramid, built with nested loops.\non mouseUp\n  b2kClear\n  repeat with row = 1 to 5\n    repeat with c = 1 to (6 - row)\n      put 120 + (row - 1) * 30 + (c - 1) * 60 into x\n      b2kSpawnBox x, 330 - row * 46, 54, 42, \"green\"\n    end repeat\n  end repeat\nend mouseUp"
    };
    function runPg() { if (pgCode) pgRunner.run(pgCode.value); }
    var pgRun = document.getElementById("pgRun"), pgClear = document.getElementById("pgClear");
    if (pgRun) pgRun.addEventListener("click", runPg);
    if (pgClear) pgClear.addEventListener("click", function () { pgWorld.clear(); setOut("cleared."); });
    if (pgCode) pgCode.addEventListener("keydown", function (e) { if ((e.metaKey || e.ctrlKey) && e.key === "Enter") { e.preventDefault(); runPg(); } });
    [].forEach.call(document.querySelectorAll(".lchip[data-preset]"), function (c) {
      c.addEventListener("click", function () { var s = PRESETS[c.dataset.preset]; if (s && pgCode) { pgCode.value = s; runPg(); } });
    });
  }

  /* =========================================================
     Scroll-spy, scroll-reveal, smooth nav
     ========================================================= */
  var spyLinks = [].slice.call(document.querySelectorAll('.menu-links a[href^="#"]'));
  var byId = {}; spyLinks.forEach(function (a) { byId[a.getAttribute("href").slice(1)] = a; });
  if ("IntersectionObserver" in window && document.querySelector("section.bay")) {
    var spy = new IntersectionObserver(function (es) {
      es.forEach(function (e) {
        if (!e.isIntersecting) return;
        spyLinks.forEach(function (a) { a.classList.remove("active"); a.removeAttribute("aria-current"); });
        var a = byId[e.target.id]; if (a) { a.classList.add("active"); a.setAttribute("aria-current", "true"); }
      });
    }, { rootMargin: "-45% 0px -50% 0px", threshold: 0 });
    [].forEach.call(document.querySelectorAll("section.bay[id]"), function (s) { spy.observe(s); });

    var rev = new IntersectionObserver(function (es) {
      es.forEach(function (e) { if (e.isIntersecting) { e.target.classList.add("in"); rev.unobserve(e.target); } });
    }, { threshold: 0.12 });
    [].forEach.call(document.querySelectorAll(".reveal"), function (el) { rev.observe(el); });
  } else {
    [].forEach.call(document.querySelectorAll(".reveal"), function (el) { el.classList.add("in"); });
  }

  function scrollToId(id) { var el = document.getElementById(id); if (el) el.scrollIntoView({ behavior: reduceMotion ? "auto" : "smooth", block: "start" }); }

  /* =========================================================
     The floating Message Box
     ========================================================= */
  var msgbox = document.getElementById("msgbox"), msgInput = document.getElementById("msgInput");
  var msgOut = document.getElementById("msgOut"), msgFab = document.getElementById("msgFab");
  if (msgbox && msgInput && msgFab) {
    function toggleMsg(force) {
      var open = force !== undefined ? force : msgbox.hidden;
      msgbox.hidden = !open;
      msgFab.setAttribute("aria-expanded", open ? "true" : "false");
      msgFab.textContent = open ? "⌨ Message ▾" : "⌨ Message";
      if (open) msgInput.focus();
    }
    function say(s) { if (msgOut) msgOut.textContent = s; }
    var SECT = { playground: "playground", features: "features", how: "how", "how it works": "how", examples: "examples", faq: "faq", about: "about", "what it is": "about", whatsnew: "whatsnew", "whats new": "whatsnew", "what's new": "whatsnew", news: "whatsnew", start: "start", "get started": "start", home: "top", top: "top" };
    function runMsg(raw) {
      var s = raw.trim(); if (!s) return; var low = s.toLowerCase(); msgInput.value = "";
      if (low === "help" || low === "?") { say("go to <section> · run · clear · b2kSpawnBall x,y,d · help"); return; }
      if (low === "run") { if (pgRunner) { runPg(); say("ran"); scrollToId("playground"); } return; }
      if (low === "clear") { if (pgWorld) { pgWorld.clear(); say("cleared"); scrollToId("playground"); } return; }
      var m = low.match(/^(?:go to|go|show|open)\s+(.+)$/);
      if (m) { var key = m[1].trim(); if (key === "docs" || key === "documentation") { location.href = "docs/index.html"; return; } var id = SECT[key]; if (id) { scrollToId(id); say(""); } else say('No section "' + key + '"'); return; }
      if (/^(b2k|put |answer |repeat|set )/i.test(s)) { if (pgRunner) { pgRunner.exec1(s); scrollToId("playground"); } return; }
      say('Can\'t understand "' + raw.trim() + '"');
    }
    msgFab.addEventListener("click", function () { toggleMsg(); });
    msgbox.addEventListener("submit", function (e) { e.preventDefault(); runMsg(msgInput.value); });
    msgInput.addEventListener("keydown", function (e) { if (e.key === "Escape") toggleMsg(false); });
    document.addEventListener("keydown", function (e) {
      if (e.metaKey || e.ctrlKey || e.altKey) return;
      var tag = (e.target.tagName || "").toLowerCase();
      if (tag === "input" || tag === "textarea" || e.target.isContentEditable) return;
      if (e.key === "m" || e.key === "M") toggleMsg();
    });
  }
})();
