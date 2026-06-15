/* ===========================================================
   Box2Dxt site — the interactive HyperCard stack
   1) Mobile menu toggle
   2) The hero physics toy: tumbling, stacking crates (exposes a
      small API so the Message Box can drive it)
   3) Stack navigation: flip cards with transitions, keyboard,
      deep links + history, a Home launcher
   4) The Message Box: type HyperTalk-ish commands
   Vanilla JS, no libraries. Degrades to a plain page without JS.
   =========================================================== */
(function () {
  "use strict";
  var INK = "#17140d";
  var reduceMotion = window.matchMedia && matchMedia("(prefers-reduced-motion: reduce)").matches;

  /* ---------- Mobile menu ---------- */
  var toggle = document.getElementById("menuToggle");
  var links = document.getElementById("menuLinks");
  if (toggle && links) {
    toggle.addEventListener("click", function () {
      var open = links.classList.toggle("open");
      toggle.setAttribute("aria-expanded", open ? "true" : "false");
    });
  }

  /* =========================================================
     Physics toy
     ========================================================= */
  var demo = null;
  var canvas = document.getElementById("physics");
  if (canvas && canvas.getContext) {
    var ctx = canvas.getContext("2d");
    var CRATES = ["#e8702a", "#2f5fae", "#3f8f5b", "#d23b3b", "#e8a23a"];
    var BALLS = ["#2a2620", "#3a3530"];
    var GRAV = 1700, REST = 0.14, WALL_REST = 0.3, FRICTION = 0.18;
    var SLOP = 0.5, CORRECT = 0.8, ITER = 6, DT = 1 / 120, MAXV = 2600, MAXSPIN = 16, MAX_BODIES = 24;

    var W = 0, H = 0, dpr = 1, bodies = [], gravityOn = true;
    var held = null, heldSavedInv = 0;
    var pointer = { x: 0, y: 0, active: false };
    var interacted = false, running = false, last = 0, acc = 0;

    var rand = function (a, b) { return a + Math.random() * (b - a); };

    function roundRect(x, y, w, h, r) {
      ctx.beginPath();
      ctx.moveTo(x + r, y);
      ctx.arcTo(x + w, y, x + w, y + h, r);
      ctx.arcTo(x + w, y + h, x, y + h, r);
      ctx.arcTo(x, y + h, x, y, r);
      ctx.arcTo(x, y, x + w, y, r);
      ctx.closePath();
    }
    function resize() {
      var rect = canvas.getBoundingClientRect();
      W = Math.max(1, rect.width); H = Math.max(1, rect.height);
      dpr = Math.min(window.devicePixelRatio || 1, 2);
      canvas.width = Math.round(W * dpr); canvas.height = Math.round(H * dpr);
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      for (var i = 0; i < bodies.length; i++) {
        bodies[i].x = Math.min(Math.max(bodies[i].r, bodies[i].x), W - bodies[i].r);
        bodies[i].y = Math.min(Math.max(bodies[i].r, bodies[i].y), H - bodies[i].r);
      }
    }
    function makeBody(x, y, r, shape, color) {
      return { x: x, y: y, vx: rand(-40, 40), vy: rand(0, 40), r: r,
               angle: rand(-0.3, 0.3), spin: rand(-2, 2), shape: shape, color: color, invMass: 1 / (r * r) };
    }
    function spawn(x, y) {
      var r = rand(15, 27), ball = Math.random() < 0.22;
      return makeBody(x, y, r, ball ? "ball" : "crate",
        ball ? BALLS[(Math.random() * BALLS.length) | 0] : CRATES[(Math.random() * CRATES.length) | 0]);
    }
    function seed() {
      bodies = [];
      var n = W < 420 ? 9 : 13;
      for (var i = 0; i < n; i++) bodies.push(spawn(rand(30, W - 30), rand(-H, H * 0.35)));
    }
    function dropAt(x, y) {
      if (bodies.length >= MAX_BODIES) bodies.shift();
      var b = spawn(x, y); b.vx = rand(-60, 60); b.vy = rand(-30, 40); b.spin = rand(-5, 5);
      bodies.push(b);
    }
    function step() {
      var i, j, b;
      for (i = 0; i < bodies.length; i++) {
        b = bodies[i];
        b.angle += b.spin * DT; b.spin *= 0.992;
        if (b === held) continue;
        if (gravityOn) b.vy += GRAV * DT;
        b.x += b.vx * DT; b.y += b.vy * DT;
        var sp = Math.hypot(b.vx, b.vy);
        if (sp > MAXV) { b.vx *= MAXV / sp; b.vy *= MAXV / sp; }
        if (b.spin > MAXSPIN) b.spin = MAXSPIN; else if (b.spin < -MAXSPIN) b.spin = -MAXSPIN;
      }
      if (held) {
        var px = Math.min(Math.max(held.r, pointer.x), W - held.r);
        var py = Math.min(Math.max(held.r, pointer.y), H - held.r);
        held.vx = (px - held.x) / DT; held.vy = (py - held.y) / DT;
        held.x = px; held.y = py;
      }
      for (var it = 0; it < ITER; it++) {
        for (i = 0; i < bodies.length; i++) {
          for (j = i + 1; j < bodies.length; j++) {
            var a = bodies[i], c = bodies[j];
            var dx = c.x - a.x, dy = c.y - a.y, dist = Math.hypot(dx, dy), min = a.r + c.r;
            if (dist >= min || dist === 0) continue;
            var nx = dx / dist, ny = dy / dist, pen = min - dist, im = a.invMass + c.invMass;
            var corr = (Math.max(pen - SLOP, 0) / im) * CORRECT;
            a.x -= nx * corr * a.invMass; a.y -= ny * corr * a.invMass;
            c.x += nx * corr * c.invMass; c.y += ny * corr * c.invMass;
            var rvx = c.vx - a.vx, rvy = c.vy - a.vy, vn = rvx * nx + rvy * ny;
            if (vn < 0) {
              var jn = -(1 + REST) * vn / im;
              a.vx -= jn * nx * a.invMass; a.vy -= jn * ny * a.invMass;
              c.vx += jn * nx * c.invMass; c.vy += jn * ny * c.invMass;
              var tx = -ny, ty = nx, vt = (c.vx - a.vx) * tx + (c.vy - a.vy) * ty;
              var jt = -vt * FRICTION / im;
              a.vx -= jt * tx * a.invMass; a.vy -= jt * ty * a.invMass;
              c.vx += jt * tx * c.invMass; c.vy += jt * ty * c.invMass;
              var kick = vt * 0.03; a.spin -= kick; c.spin += kick;
            }
          }
        }
        for (i = 0; i < bodies.length; i++) {
          b = bodies[i];
          if (b === held) continue;
          if (b.x < b.r) { b.x = b.r; if (b.vx < 0) b.vx = -b.vx * WALL_REST; b.spin *= 0.8; }
          else if (b.x > W - b.r) { b.x = W - b.r; if (b.vx > 0) b.vx = -b.vx * WALL_REST; b.spin *= 0.8; }
          if (b.y < b.r) { b.y = b.r; if (b.vy < 0) b.vy = -b.vy * WALL_REST; }
          else if (b.y > H - b.r) {
            b.y = H - b.r; if (b.vy > 0) b.vy = -b.vy * WALL_REST;
            b.vx *= 0.985; b.spin = b.spin * 0.6 + (b.vx / b.r) * 0.4;
          }
        }
      }
    }
    function drawCrate(b) {
      var s = b.r * 1.5, in1 = s * 0.13;
      roundRect(b.x - s / 2 + 3, b.y - s / 2 + 4, s, s, s * 0.16);
      ctx.fillStyle = "rgba(23,20,13,0.16)"; ctx.fill();
      ctx.save(); ctx.translate(b.x, b.y); ctx.rotate(b.angle);
      roundRect(-s / 2, -s / 2, s, s, s * 0.16);
      ctx.fillStyle = b.color; ctx.fill();
      ctx.lineWidth = 2.4; ctx.strokeStyle = INK; ctx.stroke();
      var k = s * 0.5 - in1;
      ctx.lineWidth = 2; ctx.strokeStyle = "rgba(23,20,13,0.8)";
      ctx.beginPath(); ctx.moveTo(-k, -k); ctx.lineTo(k, k); ctx.moveTo(k, -k); ctx.lineTo(-k, k); ctx.stroke();
      ctx.lineWidth = 1.5; ctx.strokeStyle = "rgba(23,20,13,0.4)";
      roundRect(-s / 2 + in1, -s / 2 + in1, s - in1 * 2, s - in1 * 2, s * 0.08); ctx.stroke();
      ctx.restore();
    }
    function drawBall(b) {
      ctx.beginPath(); ctx.arc(b.x + 2.5, b.y + 4, b.r, 0, 7); ctx.fillStyle = "rgba(23,20,13,0.16)"; ctx.fill();
      ctx.beginPath(); ctx.arc(b.x, b.y, b.r, 0, 7); ctx.fillStyle = b.color; ctx.fill();
      ctx.lineWidth = 2.4; ctx.strokeStyle = INK; ctx.stroke();
      ctx.save(); ctx.translate(b.x, b.y); ctx.rotate(b.angle);
      ctx.beginPath(); ctx.arc(-b.r * 0.34, -b.r * 0.34, b.r * 0.24, 0, 7); ctx.fillStyle = "rgba(255,255,255,0.55)"; ctx.fill();
      ctx.beginPath(); ctx.arc(b.r * 0.5, 0, b.r * 0.13, 0, 7); ctx.fillStyle = "rgba(255,255,255,0.35)"; ctx.fill();
      ctx.restore();
    }
    function draw() {
      ctx.clearRect(0, 0, W, H);
      for (var i = 0; i < bodies.length; i++) bodies[i].shape === "ball" ? drawBall(bodies[i]) : drawCrate(bodies[i]);
    }
    function frame(t) {
      if (!running) return;
      if (!last) last = t;
      acc += Math.min((t - last) / 1000, 0.05); last = t;
      var guard = 0;
      while (acc >= DT && guard < 8) { step(); acc -= DT; guard++; }
      draw();
      requestAnimationFrame(frame);
    }
    function start() { if (!running) { running = true; last = 0; requestAnimationFrame(frame); } }
    function stop() { running = false; }

    function pt(e) {
      var r = canvas.getBoundingClientRect();
      return { x: (e.touches ? e.touches[0].clientX : e.clientX) - r.left,
               y: (e.touches ? e.touches[0].clientY : e.clientY) - r.top };
    }
    function onDown(e) {
      var p = pt(e); pointer.x = p.x; pointer.y = p.y; pointer.active = true;
      interacted = true; hideHint();
      var best = null, bestD = Infinity;
      for (var i = 0; i < bodies.length; i++) {
        var b = bodies[i], d = Math.hypot(b.x - p.x, b.y - p.y);
        if (d <= b.r + 6 && d < bestD) { best = b; bestD = d; }
      }
      if (best) { held = best; heldSavedInv = best.invMass; best.invMass = 0; } else dropAt(p.x, p.y);
      e.preventDefault();
    }
    function onMove(e) { if (pointer.active) { var p = pt(e); pointer.x = p.x; pointer.y = p.y; e.preventDefault(); } }
    function onUp() {
      pointer.active = false;
      if (held) { held.invMass = heldSavedInv; held.spin = Math.max(-MAXSPIN, Math.min(MAXSPIN, -held.vx / held.r * 0.4)); held = null; }
    }
    canvas.addEventListener("mousedown", onDown);
    window.addEventListener("mousemove", onMove);
    window.addEventListener("mouseup", onUp);
    canvas.addEventListener("touchstart", onDown, { passive: false });
    canvas.addEventListener("touchmove", onMove, { passive: false });
    window.addEventListener("touchend", onUp);

    var resetBtn = document.getElementById("demoReset");
    var gravBtn = document.getElementById("demoGravity");
    var hint = document.getElementById("demoHint");
    function hideHint() { if (hint) { hint.style.transition = "opacity .4s"; hint.style.opacity = "0"; } }

    function toggleGravity() {
      gravityOn = !gravityOn;
      if (gravBtn) gravBtn.textContent = "GRAVITY: " + (gravityOn ? "ON" : "OFF");
      if (!gravityOn) for (var i = 0; i < bodies.length; i++) bodies[i].vy -= 120;
      return gravityOn;
    }
    if (resetBtn) resetBtn.addEventListener("click", function () { seed(); interacted = true; hideHint(); });
    if (gravBtn) gravBtn.addEventListener("click", function () { toggleGravity(); interacted = true; hideHint(); });

    resize(); seed();
    window.addEventListener("resize", resize);
    document.addEventListener("visibilitychange", function () { if (document.hidden) stop(); });
    setTimeout(function () { if (!interacted) hideHint(); }, 6000);

    demo = {
      start: start, stop: stop,
      drop: function () { dropAt(rand(W * 0.3, W * 0.7), 30); interacted = true; hideHint(); },
      reset: function () { seed(); },
      gravity: toggleGravity
    };
    // if there's no stack to drive start/stop, just run it
    if (!document.getElementById("stackBody")) start();
  }

  /* =========================================================
     The stack: flip between cards
     ========================================================= */
  var stackBody = document.getElementById("stackBody");
  if (stackBody) {
    var order = ["home", "about", "paste", "features", "how", "examples", "docs", "start"];
    var cards = {}, titles = {};
    [].forEach.call(document.querySelectorAll(".card"), function (c) {
      cards[c.dataset.card] = c; titles[c.dataset.card] = c.dataset.title || c.dataset.card;
    });
    var current = "home";
    var stackTitle = document.getElementById("stackTitle");
    var cardName = document.getElementById("cardName");
    var cardIdx = document.getElementById("cardIdx");
    var cardTot = document.getElementById("cardTot");
    if (cardTot) cardTot.textContent = order.length;

    function setChrome(name) {
      var idx = order.indexOf(name);
      if (stackTitle) stackTitle.textContent = "Box2Dxt — " + titles[name];
      if (cardName) cardName.textContent = titles[name];
      if (cardIdx) cardIdx.textContent = idx + 1;
      if (links) [].forEach.call(links.querySelectorAll("a[data-go]"), function (a) {
        a.classList.toggle("active", a.dataset.go === name);
      });
    }

    function show(name, hist) {
      if (!cards[name]) name = "home";
      if (name === current) return;
      var inc = cards[name], out = cards[current];
      var dir = order.indexOf(name) >= order.indexOf(current) ? "next" : "prev";
      if (name === "home") dir = "iris";
      inc.scrollTop = 0;

      if (reduceMotion) {
        for (var k in cards) if (cards[k] !== inc) { cards[k].classList.remove("is-active"); cards[k].style.cssText = ""; }
        inc.classList.add("is-active");
      } else {
        inc.classList.add("is-active");
        inc.style.transition = "none";
        inc.style.opacity = "0";
        inc.style.transform = dir === "prev" ? "translateX(-36px)" : dir === "iris" ? "scale(.97)" : "translateX(36px)";
        void inc.offsetWidth;                       // reflow so the start state sticks
        inc.style.transition = "";
        inc.style.opacity = "1";
        inc.style.transform = "none";
        if (out && out !== inc) {
          out.style.transition = "";
          out.style.opacity = "0";
          out.style.transform = dir === "prev" ? "translateX(36px)" : dir === "iris" ? "scale(1.03)" : "translateX(-36px)";
          (function (o) { setTimeout(function () { o.classList.remove("is-active"); o.style.cssText = ""; }, 320); })(out);
        }
      }
      current = name;
      setChrome(name);
      if (demo) { if (name === "home") demo.start(); else demo.stop(); }

      if (hist === "replace") history.replaceState({ card: name }, "", "#" + name);
      else if (hist !== false) { try { history.pushState({ card: name }, "", "#" + name); } catch (e) { location.hash = name; } }
    }

    function go(delta) {
      var i = order.indexOf(current);
      show(order[(i + delta + order.length) % order.length]);
    }

    // wire nav + any [data-go] element
    var navHome = document.getElementById("navHome");
    var navPrev = document.getElementById("navPrev");
    var navNext = document.getElementById("navNext");
    var winHome = document.getElementById("winHome");
    if (navHome) navHome.addEventListener("click", function () { show("home"); });
    if (winHome) winHome.addEventListener("click", function () { show("home"); });
    if (navPrev) navPrev.addEventListener("click", function () { go(-1); });
    if (navNext) navNext.addEventListener("click", function () { go(1); });

    document.addEventListener("click", function (e) {
      var t = e.target.closest ? e.target.closest("[data-go]") : null;
      if (!t) return;
      e.preventDefault();
      show(t.dataset.go);
      if (links) { links.classList.remove("open"); if (toggle) toggle.setAttribute("aria-expanded", "false"); }
    });

    window.addEventListener("popstate", function (e) {
      var name = (e.state && e.state.card) || (location.hash || "").replace("#", "") || "home";
      show(name, false);
    });

    /* ---------- The Message Box ---------- */
    var msgbox = document.getElementById("msgbox");
    var msgInput = document.getElementById("msgInput");
    var msgOut = document.getElementById("msgOut");
    var msgToggle = document.getElementById("msgToggle");
    function toggleMsg(force) {
      var open = force !== undefined ? force : msgbox.hidden;
      msgbox.hidden = !open;
      if (msgToggle) msgToggle.textContent = open ? "Message ▾" : "Message ▸";
      if (open && msgInput) msgInput.focus();
    }
    function say(s) { if (msgOut) msgOut.textContent = s; }
    var ALIAS = { start: "start", "get started": "start", "getting started": "start", learn: "docs",
      documentation: "docs", example: "examples", feature: "features", "what it is": "about", overview: "home" };
    function resolveCard(t) {
      t = t.trim();
      if (cards[t]) return t;
      for (var k in cards) if (titles[k].toLowerCase() === t) return k;
      if (ALIAS[t]) return ALIAS[t];
      for (var k2 in cards) if (titles[k2].toLowerCase().indexOf(t) >= 0 || k2.indexOf(t) >= 0) return k2;
      return null;
    }
    function runMsg(raw) {
      var s = (raw || "").trim().toLowerCase();
      if (!s) return;
      if (msgInput) msgInput.value = "";
      if (s === "help" || s === "?") { say("go to <card> · next · prev · home · spawn · reset · gravity"); return; }
      if (s === "home" || s === "go home") { show("home"); say(""); return; }
      if (s === "next" || s === "go next") { go(1); say(""); return; }
      if (s === "prev" || s === "back" || s === "go prev" || s === "go back") { go(-1); say(""); return; }
      var m = s.match(/^(?:go to|go|find|show|open)\s+(?:card\s+)?["']?([a-z ]+?)["']?$/);
      if (m) { var key = resolveCard(m[1]); if (key) { show(key); say(""); } else say('No card "' + m[1] + '".'); return; }
      if (/spawn|crate|\bbox\b|drop|b2kspawn/.test(s)) { if (current !== "home") show("home"); if (demo) demo.drop(); say("+1 crate"); return; }
      if (/reset/.test(s)) { if (current !== "home") show("home"); if (demo) demo.reset(); say("reset"); return; }
      if (/gravity/.test(s)) { if (current !== "home") show("home"); var g = demo && demo.gravity(); say("gravity " + (g ? "on" : "off")); return; }
      say('Can\'t understand "' + raw.trim() + '".');
    }
    if (msgToggle) msgToggle.addEventListener("click", function () { toggleMsg(); });
    if (msgbox) msgbox.addEventListener("submit", function (e) { e.preventDefault(); runMsg(msgInput.value); });
    if (msgInput) msgInput.addEventListener("keydown", function (e) { if (e.key === "Escape") toggleMsg(false); });

    /* ---------- Keyboard ---------- */
    document.addEventListener("keydown", function (e) {
      if (e.metaKey || e.ctrlKey || e.altKey) return;
      var tag = (e.target.tagName || "").toLowerCase();
      if (tag === "input" || tag === "textarea" || e.target.isContentEditable) return;
      if (e.key === "ArrowRight") { go(1); e.preventDefault(); }
      else if (e.key === "ArrowLeft") { go(-1); e.preventDefault(); }
      else if (e.key === "Home" || e.key === "h" || e.key === "H") show("home");
      else if (e.key === "m" || e.key === "M") toggleMsg();
    });

    /* ---------- Boot ---------- */
    setChrome("home");
    if (demo) demo.start();
    var initial = (location.hash || "").replace("#", "");
    if (initial && cards[initial] && initial !== "home") show(initial, "replace");
    else history.replaceState({ card: "home" }, "", "#home");
  }
})();
