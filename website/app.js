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
      "use strict";
      var BUD, outbox, ITEMDELIM, RESULT, handlers, funcs;

      /* ---------- value helpers ---------- */
      function isNumStr(v) { if (typeof v === "number") return isFinite(v); if (typeof v !== "string") return false; var s = v.trim(); return s !== "" && !isNaN(Number(s)); }
      function toNum(v) { if (typeof v === "number") return v; if (typeof v === "boolean") return v ? 1 : 0; var n = parseFloat(v); return isNaN(n) ? 0 : n; }
      function toBool(v) { if (typeof v === "boolean") return v; if (typeof v === "number") return v !== 0; return ("" + v).toLowerCase().trim() === "true"; }
      function fmt(n) { if (!isFinite(n)) return "" + n; if (Math.round(n) === n && Math.abs(n) < 1e15) return "" + n; var s = n.toFixed(6); return s.replace(/0+$/, "").replace(/\.$/, ""); }
      function toStr(v) { if (typeof v === "boolean") return v ? "true" : "false"; if (typeof v === "number") return fmt(v); return v == null ? "" : "" + v; }
      function budget() { if (--BUD < 0) throw { pg: "script too long — stopped" }; }
      function out(s) { outbox.push(toStr(s)); }
      function getVar(name, vars) { return vars[name] !== undefined ? vars[name] : 0; }

      var CONSTS = { empty: "", space: " ", tab: "\t", "return": "\n", cr: "\n", crlf: "\r\n", linefeed: "\n", lf: "\n", comma: ",", colon: ":", quote: '"', slash: "/", "null": "", nullchar: "", pi: Math.PI, "true": true, "false": false, up: "up", down: "down" };
      var ORD = { first: 1, second: 2, third: 3, fourth: 4, fifth: 5, sixth: 6, seventh: 7, eighth: 8, ninth: 9, tenth: 10, last: -1, middle: 0, any: -2 };
      var CHUNKW = { char: "char", chars: "char", character: "char", characters: "char", word: "word", words: "word", item: "item", items: "item", line: "line", lines: "line", token: "word", tokens: "word" };
      var CHUNKKEYS = Object.keys(CHUNKW), ORDKEYS = Object.keys(ORD);

      /* ---------- lexer ---------- */
      function lex(s) {
        var t = [], i = 0, n = s.length, two = { ">=": 1, "<=": 1, "<>": 1, "&&": 1 };
        while (i < n) {
          var c = s[i];
          if (c === " " || c === "\t") { i++; continue; }
          if (c === '"') { var j = i + 1, v = ""; while (j < n && s[j] !== '"') v += s[j++]; i = j + 1; t.push({ k: "str", v: v }); continue; }
          if (/[0-9]/.test(c) || (c === "." && /[0-9]/.test(s[i + 1] || ""))) { var num = ""; while (i < n && /[0-9.]/.test(s[i])) num += s[i++]; t.push({ k: "num", v: parseFloat(num) }); continue; }
          if (/[A-Za-z_]/.test(c)) { var id = ""; while (i < n && /[A-Za-z0-9_]/.test(s[i])) id += s[i++]; t.push({ k: "id", v: id }); continue; }
          if (c === "≠") { t.push({ k: "op", v: "<>" }); i++; continue; }
          var pr = s.substr(i, 2); if (two[pr]) { t.push({ k: "op", v: pr }); i += 2; continue; }
          if ("+-*/^&=<>(),".indexOf(c) >= 0) { t.push({ k: "op", v: c }); i++; continue; }
          i++;
        }
        return t;
      }

      /* ---------- chunk + compare helpers ---------- */
      function parts(type, src) {
        var s = toStr(src);
        if (type === "char") return s.split("");
        if (type === "item") return s.split(ITEMDELIM);
        if (type === "line") return s.split("\n");
        var w = s.trim(); return w === "" ? [] : w.split(/\s+/);
      }
      function joinParts(type, arr) { return arr.join(type === "item" ? ITEMDELIM : type === "line" ? "\n" : type === "word" ? " " : ""); }
      function resolveIdx(i, len) { i = Math.round(i); if (i < 0) i = len + i + 1; return i; }
      function chunk(type, a, b, src) { var arr = parts(type, src), len = arr.length, x = resolveIdx(a, len), y = resolveIdx(b, len); if (x < 1) x = 1; if (y > len) y = len; if (x > y) return ""; return joinParts(type, arr.slice(x - 1, y)); }
      function countChunks(type, src) { return type === "char" ? toStr(src).length : parts(type, src).length; }
      function ordChunk(type, ord, src) { var arr = parts(type, src), len = arr.length, i; if (ord === -1) i = len; else if (ord === 0) i = Math.ceil(len / 2); else if (ord === -2) i = 1 + Math.floor(Math.random() * len); else i = ord; return (i < 1 || i > len) ? "" : arr[i - 1]; }
      function isType(v, t) { if (t === "number") return isNumStr(v); if (t === "integer") return isNumStr(v) && Number.isInteger(Number(v)); if (t === "point") return /^-?\d+,-?\d+$/.test(toStr(v).trim()); if (t === "boolean" || t === "logical") return ["true", "false"].indexOf(toStr(v).toLowerCase()) >= 0; return false; }
      function looseEq(a, b) { if (isNumStr(a) && isNumStr(b)) return toNum(a) === toNum(b); return toStr(a).toLowerCase() === toStr(b).toLowerCase(); }
      function cmp(o, a, b) { var na = isNumStr(a) && isNumStr(b), x = na ? toNum(a) : toStr(a).toLowerCase(), y = na ? toNum(b) : toStr(b).toLowerCase(); return o === ">" ? x > y : o === "<" ? x < y : o === ">=" ? x >= y : x <= y; }
      function listNums(a) { if (a.length === 1 && typeof a[0] === "string" && a[0].indexOf(ITEMDELIM) >= 0) return a[0].split(ITEMDELIM).map(toNum); return a.map(toNum); }

      /* ---------- builtin functions + properties ---------- */
      function applyFn(name, a, vars) {
        switch (name) {
          case "random": return 1 + Math.floor(Math.random() * Math.max(1, Math.round(toNum(a[0]))));
          case "abs": return Math.abs(toNum(a[0]));
          case "round": return a.length > 1 ? Math.round(toNum(a[0]) * Math.pow(10, toNum(a[1]))) / Math.pow(10, toNum(a[1])) : Math.round(toNum(a[0]));
          case "trunc": return Math.trunc(toNum(a[0]));
          case "sqrt": return Math.sqrt(toNum(a[0]));
          case "sin": return Math.sin(toNum(a[0])); case "cos": return Math.cos(toNum(a[0])); case "tan": return Math.tan(toNum(a[0]));
          case "atan": return Math.atan(toNum(a[0])); case "exp": return Math.exp(toNum(a[0])); case "ln": return Math.log(toNum(a[0])); case "log2": return Math.log(toNum(a[0])) / Math.LN2;
          case "min": return Math.min.apply(null, listNums(a)); case "max": return Math.max.apply(null, listNums(a));
          case "sum": { var ns = listNums(a), s = 0, i; for (i = 0; i < ns.length; i++) s += ns[i]; return s; }
          case "average": case "avg": { var n2 = listNums(a), s2 = 0, j; if (!n2.length) return 0; for (j = 0; j < n2.length; j++) s2 += n2[j]; return s2 / n2.length; }
          case "length": return toStr(a[0]).length;
          case "toupper": case "upper": return toStr(a[0]).toUpperCase();
          case "tolower": case "lower": return toStr(a[0]).toLowerCase();
          case "numtochar": return String.fromCharCode(toNum(a[0]));
          case "chartonum": return toStr(a[0]).charCodeAt(0) || 0;
          case "offset": return toStr(a[1]).toLowerCase().indexOf(toStr(a[0]).toLowerCase()) + 1;
          case "value": return evalExpr(toStr(a[0]), vars || {});
          case "milliseconds": case "millisecs": return Date.now();
          case "seconds": case "secs": return Math.floor(Date.now() / 1000);
          case "ticks": return Math.floor(Date.now() / 1000 * 60);
          case "date": return new Date().toLocaleDateString();
          case "time": return new Date().toLocaleTimeString();
          default: if (funcs[name]) return callUser(funcs[name], a); return "";
        }
      }
      function propVal(name) {
        switch (name) {
          case "milliseconds": case "millisecs": return Date.now();
          case "seconds": case "secs": return Math.floor(Date.now() / 1000);
          case "ticks": return Math.floor(Date.now() / 1000 * 60);
          case "date": case "short date": return new Date().toLocaleDateString();
          case "long date": return new Date().toDateString();
          case "time": case "short time": case "long time": return new Date().toLocaleTimeString();
          case "result": return RESULT;
          case "itemdelimiter": case "itemdel": return ITEMDELIM;
          case "pi": return Math.PI;
          default: return undefined;
        }
      }

      /* ---------- expression evaluator ---------- */
      function evalExpr(src, vars) {
        var T = lex(src), p = 0;
        function pkOp(v) { var x = T[p]; return x && x.k === "op" && x.v === v; }
        function w(v) { var x = T[p]; return x && x.k === "id" && ("" + x.v).toLowerCase() === v; }
        function win(a) { var x = T[p]; return x && x.k === "id" && a.indexOf(("" + x.v).toLowerCase()) >= 0; }
        function eat() { return T[p++]; }
        function expectOp(v) { if (!pkOp(v)) throw { pg: "expected '" + v + "'" }; p++; }
        function pOr() { var l = pAnd(); while (w("or")) { eat(); l = toBool(l) | toBool(pAnd()) ? true : false; } return l; }
        function pAnd() { var l = pComp(); while (w("and")) { eat(); var r = pComp(); l = toBool(l) && toBool(r); } return l; }
        function pComp() {
          if (w("not")) { eat(); return !toBool(pComp()); }
          var l = pConcat();
          while (true) {
            if (pkOp("=")) { eat(); l = looseEq(l, pConcat()); }
            else if (pkOp("<>")) { eat(); l = !looseEq(l, pConcat()); }
            else if (pkOp(">")) { eat(); l = cmp(">", l, pConcat()); }
            else if (pkOp("<")) { eat(); l = cmp("<", l, pConcat()); }
            else if (pkOp(">=")) { eat(); l = cmp(">=", l, pConcat()); }
            else if (pkOp("<=")) { eat(); l = cmp("<=", l, pConcat()); }
            else if (w("is")) { eat(); var neg = false; if (w("not")) { eat(); neg = true; }
              if (w("in")) { eat(); var r = pConcat(); var res = toStr(r).toLowerCase().indexOf(toStr(l).toLowerCase()) >= 0; l = neg ? !res : res; }
              else if (win(["a", "an"])) { eat(); var ty = eat(); var r2 = isType(l, ("" + ty.v).toLowerCase()); l = neg ? !r2 : r2; }
              else { var eq = looseEq(l, pConcat()); l = neg ? !eq : eq; } }
            else if (w("contains")) { eat(); l = toStr(l).toLowerCase().indexOf(toStr(pConcat()).toLowerCase()) >= 0; }
            else if (w("in")) { eat(); var ri = pConcat(); l = toStr(ri).toLowerCase().indexOf(toStr(l).toLowerCase()) >= 0; }
            else break;
          }
          return l;
        }
        function pConcat() { var l = pAdd(); while (pkOp("&") || pkOp("&&")) { var o = eat().v; l = toStr(l) + (o === "&&" ? " " : "") + toStr(pAdd()); } return l; }
        function pAdd() { var l = pMul(); while (pkOp("+") || pkOp("-")) { var o = eat().v; var r = pMul(); l = o === "+" ? toNum(l) + toNum(r) : toNum(l) - toNum(r); } return l; }
        function pMul() { var l = pExp(); while (pkOp("*") || pkOp("/") || w("mod") || w("div")) { var o = eat().v.toLowerCase(); var r = pExp(); l = o === "*" ? toNum(l) * toNum(r) : o === "/" ? toNum(l) / toNum(r) : o === "mod" ? toNum(l) % toNum(r) : Math.floor(toNum(l) / toNum(r)); } return l; }
        function pExp() { var l = pUn(); if (pkOp("^")) { eat(); return Math.pow(toNum(l), toNum(pExp())); } return l; }
        function pUn() { if (pkOp("-")) { eat(); return -toNum(pUn()); } if (pkOp("+")) { eat(); return pUn(); } return pChunk(); }
        function pChunk() {
          if (win(CHUNKKEYS)) {
            var type = CHUNKW[("" + eat().v).toLowerCase()], a = pAdd(), b = a;
            if (w("to")) { eat(); b = pAdd(); }
            if (!w("of")) throw { pg: "expected 'of'" }; eat();
            return chunk(type, toNum(a), toNum(b), pChunk());
          }
          if (win(ORDKEYS) && T[p + 1] && T[p + 1].k === "id" && CHUNKW[("" + T[p + 1].v).toLowerCase()]) {
            var ord = ORD[("" + eat().v).toLowerCase()], ct0 = CHUNKW[("" + eat().v).toLowerCase()];
            if (w("of")) eat(); return ordChunk(ct0, ord, pChunk());
          }
          if (w("the")) { eat(); return pThe(); }
          return pAtom();
        }
        function pThe() {
          if (w("number")) { eat(); if (w("of") || w("in")) eat(); if (win(CHUNKKEYS)) { var ct = CHUNKW[("" + eat().v).toLowerCase()]; if (w("in") || w("of")) eat(); return countChunks(ct, pChunk()); } return countChunks("item", pChunk()); }
          if (win(ORDKEYS)) { var ord = ORD[("" + eat().v).toLowerCase()]; if (win(CHUNKKEYS)) { var ct2 = CHUNKW[("" + eat().v).toLowerCase()]; if (w("of")) eat(); return ordChunk(ct2, ord, pChunk()); } return ""; }
          var nm = ("" + eat().v).toLowerCase();
          if (["long", "short", "abbreviated", "abbrev", "english", "internet", "system"].indexOf(nm) >= 0 && T[p] && T[p].k === "id") nm = nm + " " + ("" + eat().v).toLowerCase();
          if (w("of") || w("in")) { eat(); return applyFn(nm, [pChunk()], vars); }
          var pv = propVal(nm); if (pv !== undefined) return pv;
          return applyFn(nm, [], vars);
        }
        function pAtom() {
          var x = eat(); if (!x) throw { pg: "unexpected end of expression" };
          if (x.k === "num") return x.v;
          if (x.k === "str") return x.v;
          if (x.k === "op" && x.v === "(") { var e = pOr(); expectOp(")"); return e; }
          if (x.k === "id") {
            var nm = ("" + x.v).toLowerCase();
            if (pkOp("(")) { eat(); var args = []; if (!pkOp(")")) { args.push(pOr()); while (pkOp(",")) { eat(); args.push(pOr()); } } expectOp(")"); return applyFn(nm, args, vars); }
            if (nm in CONSTS) return CONSTS[nm];
            if (nm === "it") return vars.it !== undefined ? vars.it : "";
            if (vars[nm] !== undefined) return vars[nm];
            return x.v; /* unquoted literal -> its own name (HyperTalk) */
          }
          throw { pg: "bad expression" };
        }
        return pOr();
      }

      /* ---------- statements ---------- */
      function stripComment(s) { var q = false, i; for (i = 0; i < s.length - 1; i++) { if (s[i] === '"') q = !q; else if (!q && s[i] === "-" && s[i + 1] === "-") return s.slice(0, i); } return s; }
      function splitArgs(s) { var out2 = [], d = 0, cur = "", q = false, i; for (i = 0; i < s.length; i++) { var c = s[i]; if (c === '"') q = !q; if (!q && c === "(") d++; else if (!q && c === ")") d--; if (!q && c === "," && d === 0) { out2.push(cur); cur = ""; } else cur += c; } if (cur.trim() !== "") out2.push(cur); return out2; }
      function evalArgs(rest, vars) { return rest.trim() === "" ? [] : splitArgs(rest).map(function (a) { return evalExpr(a, vars); }); }

      function execStmt(line, vars) {
        budget();
        var s = stripComment(line).trim(); if (s === "") return;
        var m = s.match(/^([A-Za-z_]\w*)\b([\s\S]*)$/);
        if (!m) { out(toStr(evalExpr(s, vars))); return; }
        var cmd = m[1].toLowerCase(), rest = m[2].trim(), a, mm;
        switch (cmd) {
          case "put": doPut(rest, vars); return;
          case "get": vars.it = evalExpr(rest, vars); return;
          case "set": doSet(rest, vars); return;
          case "add": mm = rest.match(/^([\s\S]*)\s+to\s+([A-Za-z_]\w*)$/i); if (mm) { var d1 = mm[2].toLowerCase(); vars[d1] = toNum(getVar(d1, vars)) + toNum(evalExpr(mm[1], vars)); } return;
          case "subtract": mm = rest.match(/^([\s\S]*)\s+from\s+([A-Za-z_]\w*)$/i); if (mm) { var d2 = mm[2].toLowerCase(); vars[d2] = toNum(getVar(d2, vars)) - toNum(evalExpr(mm[1], vars)); } return;
          case "multiply": mm = rest.match(/^([A-Za-z_]\w*)\s+by\s+([\s\S]+)$/i); if (mm) { var d3 = mm[1].toLowerCase(); vars[d3] = toNum(getVar(d3, vars)) * toNum(evalExpr(mm[2], vars)); } return;
          case "divide": mm = rest.match(/^([A-Za-z_]\w*)\s+by\s+([\s\S]+)$/i); if (mm) { var d4 = mm[1].toLowerCase(); vars[d4] = toNum(getVar(d4, vars)) / toNum(evalExpr(mm[2], vars)); } return;
          case "answer": out(toStr(evalExpr(rest.replace(/\s+with\s+[\s\S]+$/i, ""), vars))); return;
          case "ask": { var promptText = toStr(evalExpr(rest.replace(/\s+with\s+[\s\S]+$/i, ""), vars)); var dflt = rest.match(/\s+with\s+([\s\S]+)$/i); var pre = dflt ? toStr(evalExpr(dflt[1], vars)) : ""; var ans = (typeof window !== "undefined" && window.prompt) ? window.prompt(promptText || "?", pre) : null; vars.it = ans == null ? "" : ans; RESULT = ans == null ? "cancel" : ""; return; }
          case "return": throw { ret: rest ? evalExpr(rest, vars) : "" };
          case "exit": if (/^repeat\b/i.test(rest)) throw { exitRepeat: 1 }; throw { exitHandler: 1 };
          case "next": if (/^repeat\b/i.test(rest)) throw { nextRepeat: 1 }; return;
          case "pass": case "global": case "local": return;
          case "wait": return;
          case "b2kspawnbox": case "b2kspawncapsule": a = evalArgs(rest, vars); world.spawnBox(a[0], a[1], a[2], a[3], a[4]); return;
          case "b2kspawnball": a = evalArgs(rest, vars); world.spawnBall(a[0], a[1], a[2], a[3]); return;
          case "b2kgravity": world.gravity(!/^(off|false|0|no)\b/i.test(rest.trim())); return;
          case "b2kclear": world.clear(); return;
          case "b2kimpulse": a = evalArgs(rest, vars); world.impulseAll(a[0] || 0, a[1] || 0); return;
          case "b2krain": { var nn = rest ? toNum(evalExpr(rest, vars)) : 10; nn = clamp(nn, 0, 40); for (var k = 0; k < nn; k++) world.spawnBall(20 + Math.random() * (world.w() - 40), 10, 18 + Math.random() * 22); return; }
          default:
            if (handlers[cmd]) { callUser(handlers[cmd], evalArgs(rest, vars)); return; }
            if (cmd.indexOf("b2k") === 0) return;
            out('Don\'t understand "' + cmd + '"');
        }
      }
      function doPut(rest, vars) {
        var m = rest.match(/^([\s\S]*?)\s+(into|before|after)\s+([\s\S]+)$/i);
        if (!m) { out(toStr(evalExpr(rest, vars))); return; }
        var val = evalExpr(m[1], vars), mode = m[2].toLowerCase(), dest = m[3].trim().replace(/^the\s+/i, "");
        var mc = dest.match(/^(char|character|word|item|line)s?\s+([\s\S]+?)\s+of\s+([A-Za-z_]\w*)$/i);
        if (mc) {
          var type = CHUNKW[mc[1].toLowerCase()], idx = Math.round(toNum(evalExpr(mc[2], vars))), vn = mc[3].toLowerCase();
          var arr = parts(type, toStr(getVar(vn, vars) || "")), i = resolveIdx(idx, arr.length); if (i < 1) i = 1; while (arr.length < i) arr.push("");
          var ex0 = arr[i - 1] || ""; arr[i - 1] = mode === "before" ? toStr(val) + ex0 : mode === "after" ? ex0 + toStr(val) : toStr(val); vars[vn] = joinParts(type, arr); return;
        }
        var name = dest.toLowerCase(); if (!/^[a-z_]\w*$/.test(name)) return;
        if (mode === "into") vars[name] = val;
        else { var ex = vars[name] !== undefined ? toStr(vars[name]) : ""; vars[name] = mode === "before" ? toStr(val) + ex : ex + toStr(val); }
      }
      function doSet(rest, vars) {
        var m = rest.match(/^(?:the\s+)?([A-Za-z]\w*)\s+to\s+([\s\S]+)$/i); if (!m) return;
        var prop = m[1].toLowerCase(), val = evalExpr(m[2], vars);
        if (prop === "itemdelimiter" || prop === "itemdel") { ITEMDELIM = toStr(val) || ","; return; }
        if (prop === "gravity") { world.gravity(toNum(val) !== 0); return; }
        if (prop === "numberformat") return;
        vars[prop] = val;
      }

      /* ---------- blocks: if / repeat ---------- */
      function collectBlock(lines, start, openRe, closeRe) {
        var depth = 1, j = start + 1, inner = [];
        for (; j < lines.length; j++) { var t = stripComment(lines[j]).trim().toLowerCase(); if (openRe.test(t)) depth++; else if (closeRe.test(t)) { depth--; if (depth === 0) break; } inner.push(lines[j]); }
        return { inner: inner, end: j };
      }
      var IF_OPEN = /^if\b[\s\S]*\bthen$/, IF_CLOSE = /^end\s+if$/, REP_OPEN = /^repeat\b/, REP_CLOSE = /^end\s+repeat$/;
      function splitClauses(inner, firstCond) {
        var clauses = [{ cond: firstCond, body: [] }], cur = clauses[0], depth = 0, i;
        for (i = 0; i < inner.length; i++) {
          var t = stripComment(inner[i]).trim(), low = t.toLowerCase();
          if (depth === 0) {
            var me = low.match(/^else\s+if\s+([\s\S]*?)\s+then$/);
            if (me) { cur = { cond: me[1], body: [] }; clauses.push(cur); continue; }
            if (/^else\b/.test(low)) { cur = { cond: true, body: [] }; clauses.push(cur); var tail = t.replace(/^else\b\s*/i, ""); if (tail.trim() !== "") cur.body.push(tail); continue; }
          }
          if (IF_OPEN.test(low) || REP_OPEN.test(low)) depth++;
          else if (/^end\s+(if|repeat)$/.test(low)) depth--;
          cur.body.push(inner[i]);
        }
        return clauses;
      }
      function doIf(lines, i, vars) {
        var s = stripComment(lines[i]).trim();
        var m = s.match(/^if\s+([\s\S]*?)\s+then\b([\s\S]*)$/i); if (!m) return i + 1;
        var firstCond = m[1], thenTail = m[2].trim();
        if (thenTail !== "") { var two = thenTail.split(/\s+else\s+/i); if (toBool(evalExpr(firstCond, vars))) execStmt(two[0], vars); else if (two[1] !== undefined) execStmt(two[1], vars); return i + 1; }
        var blk = collectBlock(lines, i, IF_OPEN, IF_CLOSE), clauses = splitClauses(blk.inner, firstCond), c;
        for (c = 0; c < clauses.length; c++) { if (clauses[c].cond === true || toBool(evalExpr(clauses[c].cond, vars))) { execBlock(clauses[c].body, vars); break; } }
        return blk.end + 1;
      }
      function doRepeat(lines, i, vars) {
        var s = stripComment(lines[i]).trim(), spec = s.replace(/^repeat\b\s*/i, "").trim();
        var blk = collectBlock(lines, i, REP_OPEN, REP_CLOSE), inner = blk.inner;
        function once() { try { execBlock(inner, vars); } catch (e) { if (e && e.nextRepeat) return; throw e; } }
        try {
          var mw = spec.match(/^with\s+([A-Za-z_]\w*)\s*=\s*([\s\S]+?)\s+(down\s+to|to)\s+([\s\S]+)$/i);
          if (mw) {
            var name = mw[1].toLowerCase(), a = Math.round(toNum(evalExpr(mw[2], vars))), down = /down/i.test(mw[3]), b = Math.round(toNum(evalExpr(mw[4], vars))), cnt = 0, v;
            if (down) { for (v = a; v >= b; v--) { if (++cnt > 2000) break; budget(); vars[name] = v; once(); } }
            else { for (v = a; v <= b; v++) { if (++cnt > 2000) break; budget(); vars[name] = v; once(); } }
          } else if (spec === "" || /^forever$/i.test(spec)) { for (var k = 0; k < 2000; k++) { budget(); once(); } }
          else if (/^while\b/i.test(spec)) { var cw = spec.replace(/^while\b/i, ""), g = 0; while (toBool(evalExpr(cw, vars))) { if (++g > 2000) break; budget(); once(); } }
          else if (/^until\b/i.test(spec)) { var cu = spec.replace(/^until\b/i, ""), g2 = 0; while (!toBool(evalExpr(cu, vars))) { if (++g2 > 2000) break; budget(); once(); } }
          else if (/^for\s+each\b/i.test(spec)) { var mf = spec.match(/^for\s+each\s+(char|character|word|item|line)\s+([A-Za-z_]\w*)\s+in\s+([\s\S]+)$/i); if (mf) { var type = CHUNKW[mf[1].toLowerCase()], vn = mf[2].toLowerCase(), arr = parts(type, evalExpr(mf[3], vars)), fi; for (fi = 0; fi < arr.length; fi++) { if (fi > 2000) break; budget(); vars[vn] = arr[fi]; once(); } } }
          else { var times = clamp(Math.round(toNum(evalExpr(spec.replace(/\s+times$/i, ""), vars))), 0, 4000), t2; for (t2 = 0; t2 < times; t2++) { budget(); once(); } }
        } catch (e) { if (!(e && e.exitRepeat)) throw e; }
        return blk.end + 1;
      }
      function execBlock(lines, vars) {
        var i = 0;
        while (i < lines.length) {
          budget();
          var s = stripComment(lines[i]).trim();
          if (s === "") { i++; continue; }
          var low = s.toLowerCase();
          if (/^if\b/.test(low)) { i = doIf(lines, i, vars); continue; }
          if (/^repeat\b/.test(low)) { i = doRepeat(lines, i, vars); continue; }
          if (/^(end|else)\b/.test(low)) { i++; continue; }
          execStmt(s, vars); i++;
        }
      }

      /* ---------- handlers / functions ---------- */
      function parseParams(s) { s = (s || "").trim(); return s === "" ? [] : s.split(",").map(function (x) { return x.trim().toLowerCase(); }).filter(Boolean); }
      function callUser(def, args) {
        budget(); var vars = {}, i; for (i = 0; i < def.params.length; i++) vars[def.params[i]] = args[i] !== undefined ? args[i] : "";
        var ret = "";
        try { execBlock(def.body, vars); } catch (e) { if (e && "ret" in e) ret = e.ret; else if (e && e.exitHandler) ret = ""; else throw e; }
        return ret;
      }
      function parseSource(src) {
        var raw = src.replace(/\r\n/g, "\n").split("\n"), lines = [], i;
        for (i = 0; i < raw.length; i++) { var ln = raw[i]; while (/\\\s*$/.test(ln) && i + 1 < raw.length) ln = ln.replace(/\\\s*$/, " ") + raw[++i]; lines.push(ln); }
        handlers = {}; funcs = {}; var top = [];
        for (i = 0; i < lines.length; i++) {
          var t = lines[i].trim();
          var mOn = t.match(/^(?:on|command)\s+([A-Za-z_]\w*)([\s\S]*)$/i), mFn = t.match(/^function\s+([A-Za-z_]\w*)([\s\S]*)$/i);
          if (mOn || mFn) {
            var name = (mOn ? mOn[1] : mFn[1]).toLowerCase(), params = parseParams(mOn ? mOn[2] : mFn[2]), body = [];
            i++;
            for (; i < lines.length; i++) { var et = lines[i].trim().toLowerCase().split(/\s+/); if (et[0] === "end" && et[1] === name) break; body.push(lines[i]); }
            (mOn ? handlers : funcs)[name] = { params: params, body: body };
            continue;
          }
          top.push(lines[i]);
        }
        return top;
      }
      function finish() { setOut(outbox.length ? outbox.join("  ·  ") : "ran · " + world.count() + " bodies"); }

      return {
        run: function (src, prefer) {
          BUD = 20000; outbox = []; ITEMDELIM = ","; RESULT = "";
          try {
            var top = parseSource(src), keys = Object.keys(handlers), hb = (prefer && handlers[prefer.toLowerCase()]) || (keys.length ? handlers[keys[0]] : null);
            if (hb) { try { execBlock(hb.body, {}); } catch (e) { if (!(e && e.exitHandler)) throw e; } }
            else execBlock(top, {});
            finish();
          } catch (e) { setOut("⚠ " + (e && e.pg ? e.pg : "error")); }
        },
        exec1: function (line) {
          BUD = 20000; outbox = []; ITEMDELIM = ","; RESULT = ""; parseSource("");
          try {
            var s = stripComment(line).trim(), first = (s.match(/^([A-Za-z_]\w*)/) || [])[1], lf = first ? first.toLowerCase() : "";
            var cmds = ["put", "get", "set", "add", "subtract", "multiply", "divide", "answer", "ask", "return", "exit", "next", "pass", "wait", "if", "repeat", "global", "local"];
            if (lf && (cmds.indexOf(lf) >= 0 || lf.indexOf("b2k") === 0 || handlers[lf])) execStmt(s, {});
            else out(toStr(evalExpr(s, {})));
            finish();
          } catch (e) { setOut("⚠ " + (e && e.pg ? e.pg : "error")); }
        }
      };
    })(pgWorld);

    var PRESETS = {
      tower: "-- A stack of crates, then a ball on top.\non mouseUp\n  b2kClear\n  repeat with i = 1 to 6\n    b2kSpawnBox 230, 320 - i * 46, 78, 42, \"orange\"\n  end repeat\n  b2kSpawnBall 252, 20, 44, \"blue\"\nend mouseUp",
      rain: "-- Drop a shower of balls.\non mouseUp\n  repeat 14 times\n    b2kSpawnBall random(360) + 30, 10, random(26) + 18\n  end repeat\nend mouseUp",
      zerog: "-- Turn gravity off and fill the void.\non mouseUp\n  b2kClear\n  b2kGravity off\n  repeat 12 times\n    b2kSpawnBall random(360) + 30, random(280) + 20, 30, \"teal\"\n  end repeat\nend mouseUp",
      kick: "-- Spawn some crates, then kick them up.\non mouseUp\n  b2kClear\n  repeat 5 times\n    b2kSpawnBox random(300) + 60, 300, 50, 50, \"red\"\n  end repeat\n  b2kImpulse 0, -700\nend mouseUp",
      pyramid: "-- A pyramid, built with nested loops.\non mouseUp\n  b2kClear\n  repeat with row = 1 to 5\n    repeat with c = 1 to (6 - row)\n      put 120 + (row - 1) * 30 + (c - 1) * 60 into x\n      b2kSpawnBox x, 330 - row * 46, 54, 42, \"green\"\n    end repeat\n  end repeat\nend mouseUp",
      func: "-- Define your own function and call it.\nfunction squared n\n  return n * n\nend squared\n\non mouseUp\n  b2kClear\n  repeat with i = 1 to 6\n    b2kSpawnBall 40 + i * 58, 30, 14 + squared(i), \"purple\"\n  end repeat\nend mouseUp",
      words: "-- Chunk expressions + put (watch the output line).\non mouseUp\n  put \"the quick brown fox jumps\" into s\n  put (the number of words in s) && \"words; last =\" && last word of s\n  put \"item 2 of 10,20,30 is\" && item 2 of \"10,20,30\"\nend mouseUp"
    };
    function runPg() { if (pgCode) pgRunner.run(pgCode.value, "mouseUp"); }
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
      var m = low.match(/^(?:go to|goto|show|open)\s+(.+)$/);
      if (m) { var key = m[1].trim(); if (key === "docs" || key === "documentation") { location.href = "docs/index.html"; return; } var id = SECT[key]; if (id) { scrollToId(id); say(""); return; } }
      // anything else: run it as an xTalk line/expression in the playground
      if (pgRunner) { pgRunner.exec1(s); scrollToId("playground"); }
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
