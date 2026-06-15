/* ===========================================================
   Box2Dxt site — interactive bits
   1) Mobile nav toggle
   2) A tiny self-contained 2D physics toy for the hero
      (impulse-based circle solver: gravity, walls, ball-ball
       collisions, mouse/touch grab + fling, click-to-spawn).
   No libraries. This is a *toy* — Box2Dxt is the real engine.
   =========================================================== */
(function () {
  "use strict";

  /* ---------- Mobile nav ---------- */
  var toggle = document.getElementById("navToggle");
  var links = document.querySelector(".nav-links");
  if (toggle && links) {
    toggle.addEventListener("click", function () {
      var open = links.classList.toggle("open");
      toggle.setAttribute("aria-expanded", open ? "true" : "false");
    });
    links.addEventListener("click", function (e) {
      if (e.target.tagName === "A") {
        links.classList.remove("open");
        toggle.setAttribute("aria-expanded", "false");
      }
    });
  }

  /* ---------- Physics toy ---------- */
  var canvas = document.getElementById("physics");
  if (!canvas || !canvas.getContext) return;
  var ctx = canvas.getContext("2d");

  var COLORS = ["#ff7a45", "#2dd4bf", "#a78bfa", "#ffd479", "#ff5e62", "#5b8cff"];
  var GRAV = 1700;          // px / s^2
  var REST = 0.16;          // ball-ball restitution (low → settles into a pile)
  var WALL_REST = 0.32;     // wall bounce
  var FRICTION = 0.04;      // tangential damping on contact
  var SLOP = 0.5;           // penetration allowance
  var CORRECT = 0.8;        // positional correction factor
  var ITER = 6;             // solver iterations per step
  var DT = 1 / 120;         // fixed timestep
  var MAXV = 2600;          // velocity clamp (anti-tunnel)
  var MAX_BODIES = 26;

  var W = 0, H = 0, dpr = 1;
  var bodies = [];
  var gravityOn = true;
  var held = null, heldSavedInv = 0;
  var pointer = { x: 0, y: 0, active: false };
  var interacted = false;
  var acc = 0, last = 0, running = false;

  function rand(a, b) { return a + Math.random() * (b - a); }

  function resize() {
    var rect = canvas.getBoundingClientRect();
    W = Math.max(1, rect.width);
    H = Math.max(1, rect.height);
    dpr = Math.min(window.devicePixelRatio || 1, 2);
    canvas.width = Math.round(W * dpr);
    canvas.height = Math.round(H * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    // keep existing bodies inside the new bounds
    for (var i = 0; i < bodies.length; i++) {
      var b = bodies[i];
      b.x = Math.min(Math.max(b.r, b.x), W - b.r);
      b.y = Math.min(Math.max(b.r, b.y), H - b.r);
    }
  }

  function makeBody(x, y, r, color) {
    return {
      x: x, y: y, vx: rand(-40, 40), vy: rand(0, 40),
      r: r, color: color || COLORS[(Math.random() * COLORS.length) | 0],
      invMass: 1 / (r * r)
    };
  }

  function seed() {
    bodies = [];
    var n = W < 420 ? 9 : 13;
    for (var i = 0; i < n; i++) {
      var r = rand(13, 26);
      bodies.push(makeBody(rand(r, W - r), rand(-H, H * 0.4), r));
    }
  }

  function spawnAt(x, y) {
    if (bodies.length >= MAX_BODIES) bodies.shift();
    var r = rand(13, 26);
    var b = makeBody(x, y, r);
    b.vx = rand(-60, 60); b.vy = rand(-40, 40);
    bodies.push(b);
  }

  /* one fixed physics step */
  function step() {
    var i, j, b;

    // integrate
    for (i = 0; i < bodies.length; i++) {
      b = bodies[i];
      if (b === held) continue;            // held body is driven by the pointer
      if (gravityOn) b.vy += GRAV * DT;
      b.x += b.vx * DT;
      b.y += b.vy * DT;
      // clamp speed
      var sp = Math.hypot(b.vx, b.vy);
      if (sp > MAXV) { b.vx *= MAXV / sp; b.vy *= MAXV / sp; }
    }

    // drive held body from the pointer; give it velocity for the fling
    if (held) {
      var px = Math.min(Math.max(held.r, pointer.x), W - held.r);
      var py = Math.min(Math.max(held.r, pointer.y), H - held.r);
      held.vx = (px - held.x) / DT;
      held.vy = (py - held.y) / DT;
      held.x = px; held.y = py;
    }

    // collisions (several iterations for a stable pile)
    for (var it = 0; it < ITER; it++) {
      // ball vs ball
      for (i = 0; i < bodies.length; i++) {
        for (j = i + 1; j < bodies.length; j++) {
          var a = bodies[i], c = bodies[j];
          var dx = c.x - a.x, dy = c.y - a.y;
          var dist = Math.hypot(dx, dy);
          var min = a.r + c.r;
          if (dist >= min || dist === 0) continue;

          var nx = dx / dist, ny = dy / dist;
          var pen = min - dist;
          var im = a.invMass + c.invMass;

          // positional correction
          var corr = (Math.max(pen - SLOP, 0) / im) * CORRECT;
          a.x -= nx * corr * a.invMass;
          a.y -= ny * corr * a.invMass;
          c.x += nx * corr * c.invMass;
          c.y += ny * corr * c.invMass;

          // velocity impulse
          var rvx = c.vx - a.vx, rvy = c.vy - a.vy;
          var vn = rvx * nx + rvy * ny;
          if (vn < 0) {
            var jn = -(1 + REST) * vn / im;
            a.vx -= jn * nx * a.invMass; a.vy -= jn * ny * a.invMass;
            c.vx += jn * nx * c.invMass; c.vy += jn * ny * c.invMass;
            // tangential friction
            var tx = -ny, ty = nx;
            var vt = (c.vx - a.vx) * tx + (c.vy - a.vy) * ty;
            var jt = -vt * FRICTION / im;
            a.vx -= jt * tx * a.invMass; a.vy -= jt * ty * a.invMass;
            c.vx += jt * tx * c.invMass; c.vy += jt * ty * c.invMass;
          }
        }
      }

      // walls
      for (i = 0; i < bodies.length; i++) {
        b = bodies[i];
        if (b === held) continue;
        if (b.x < b.r) { b.x = b.r; if (b.vx < 0) b.vx = -b.vx * WALL_REST; }
        else if (b.x > W - b.r) { b.x = W - b.r; if (b.vx > 0) b.vx = -b.vx * WALL_REST; }
        if (b.y < b.r) { b.y = b.r; if (b.vy < 0) b.vy = -b.vy * WALL_REST; }
        else if (b.y > H - b.r) {
          b.y = H - b.r;
          if (b.vy > 0) b.vy = -b.vy * WALL_REST;
          b.vx *= 0.985; // floor friction so the pile settles
        }
      }
    }
  }

  function draw() {
    ctx.clearRect(0, 0, W, H);
    for (var i = 0; i < bodies.length; i++) {
      var b = bodies[i];
      // soft shadow
      ctx.beginPath();
      ctx.arc(b.x, b.y + 3, b.r, 0, Math.PI * 2);
      ctx.fillStyle = "rgba(0,0,0,0.18)";
      ctx.fill();
      // ball with a top-left highlight for depth
      var g = ctx.createRadialGradient(
        b.x - b.r * 0.35, b.y - b.r * 0.4, b.r * 0.1,
        b.x, b.y, b.r
      );
      g.addColorStop(0, lighten(b.color, 0.35));
      g.addColorStop(1, b.color);
      ctx.beginPath();
      ctx.arc(b.x, b.y, b.r, 0, Math.PI * 2);
      ctx.fillStyle = g;
      ctx.fill();
      ctx.lineWidth = 1;
      ctx.strokeStyle = "rgba(0,0,0,0.22)";
      ctx.stroke();
    }
  }

  // quick hex lighten
  function lighten(hex, amt) {
    var n = parseInt(hex.slice(1), 16);
    var r = (n >> 16) & 255, g = (n >> 8) & 255, b = n & 255;
    r = Math.round(r + (255 - r) * amt);
    g = Math.round(g + (255 - g) * amt);
    b = Math.round(b + (255 - b) * amt);
    return "rgb(" + r + "," + g + "," + b + ")";
  }

  function frame(t) {
    if (!running) return;
    if (!last) last = t;
    var elapsed = (t - last) / 1000;
    last = t;
    acc += Math.min(elapsed, 0.05);   // cap to avoid spiral of death
    var guard = 0;
    while (acc >= DT && guard < 8) { step(); acc -= DT; guard++; }
    draw();
    requestAnimationFrame(frame);
  }

  function start() {
    if (running) return;
    running = true; last = 0;
    requestAnimationFrame(frame);
  }
  function stop() { running = false; }

  /* ---------- Pointer interaction ---------- */
  function canvasPoint(e) {
    var rect = canvas.getBoundingClientRect();
    var cx = (e.touches ? e.touches[0].clientX : e.clientX) - rect.left;
    var cy = (e.touches ? e.touches[0].clientY : e.clientY) - rect.top;
    return { x: cx, y: cy };
  }

  function onDown(e) {
    var p = canvasPoint(e);
    pointer.x = p.x; pointer.y = p.y; pointer.active = true;
    interacted = true; hideHint();

    // grab the nearest body under the pointer
    var best = null, bestD = Infinity;
    for (var i = 0; i < bodies.length; i++) {
      var b = bodies[i];
      var d = Math.hypot(b.x - p.x, b.y - p.y);
      if (d <= b.r + 6 && d < bestD) { best = b; bestD = d; }
    }
    if (best) {
      held = best;
      heldSavedInv = best.invMass;
      best.invMass = 0;          // immovable while held → shoves others, stays put
    } else {
      spawnAt(p.x, p.y);         // empty space → drop a new body
    }
    e.preventDefault();
  }

  function onMove(e) {
    if (!pointer.active) return;
    var p = canvasPoint(e);
    pointer.x = p.x; pointer.y = p.y;
    e.preventDefault();
  }

  function onUp() {
    pointer.active = false;
    if (held) {
      held.invMass = heldSavedInv; // restore mass; keeps tracked velocity → fling
      held = null;
    }
  }

  canvas.addEventListener("mousedown", onDown);
  window.addEventListener("mousemove", onMove);
  window.addEventListener("mouseup", onUp);
  canvas.addEventListener("touchstart", onDown, { passive: false });
  canvas.addEventListener("touchmove", onMove, { passive: false });
  window.addEventListener("touchend", onUp);

  /* ---------- Controls ---------- */
  var resetBtn = document.getElementById("demoReset");
  var gravBtn = document.getElementById("demoGravity");
  var hint = document.getElementById("demoHint");

  function hideHint() { if (hint) { hint.style.transition = "opacity .4s"; hint.style.opacity = "0"; } }

  if (resetBtn) resetBtn.addEventListener("click", function () { seed(); interacted = true; hideHint(); });
  if (gravBtn) gravBtn.addEventListener("click", function () {
    gravityOn = !gravityOn;
    gravBtn.textContent = "Gravity: " + (gravityOn ? "on" : "off");
    if (!gravityOn) { for (var i = 0; i < bodies.length; i++) { bodies[i].vy -= 120; } } // little float-up nudge
    interacted = true; hideHint();
  });

  /* ---------- Lifecycle: only run while visible ---------- */
  resize();
  seed();
  window.addEventListener("resize", resize);

  if ("IntersectionObserver" in window) {
    var io = new IntersectionObserver(function (entries) {
      if (entries[0].isIntersecting) start(); else stop();
    }, { threshold: 0.05 });
    io.observe(canvas);
  } else {
    start();
  }
  document.addEventListener("visibilitychange", function () {
    if (document.hidden) stop(); else start();
  });

  // auto-hide the hint after a few seconds even without interaction
  setTimeout(function () { if (!interacted) hideHint(); }, 6000);
})();
