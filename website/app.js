/* ===========================================================
   Box2Dxt site — interactive bits
   1) Mac-style menu toggle (mobile)
   2) A tiny self-contained physics toy for the hero: tumbling,
      stacking Box2D-style crates (+ a few cannonballs). Circle
      colliders keep it rock-stable; bodies carry an angle so they
      render as rotating crates. Grab + fling, click to drop,
      gravity toggle. No libraries — Box2Dxt is the real engine.
   =========================================================== */
(function () {
  "use strict";

  var INK = "#17140d";

  /* ---------- Menu (mobile) ---------- */
  var toggle = document.getElementById("menuToggle");
  var links = document.getElementById("menuLinks");
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

  var CRATES = ["#e8702a", "#2f5fae", "#3f8f5b", "#d23b3b", "#e8a23a"];
  var BALLS = ["#2a2620", "#3a3530"];
  var GRAV = 1700;          // px / s^2
  var REST = 0.14;          // restitution (low → settles into a pile)
  var WALL_REST = 0.3;
  var FRICTION = 0.18;      // tangential damping on contact
  var SLOP = 0.5, CORRECT = 0.8, ITER = 6;
  var DT = 1 / 120, MAXV = 2600, MAXSPIN = 16, MAX_BODIES = 24;

  var W = 0, H = 0, dpr = 1;
  var bodies = [], gravityOn = true;
  var held = null, heldSavedInv = 0, lastHeldX = 0;
  var pointer = { x: 0, y: 0, active: false };
  var interacted = false, running = false, last = 0, acc = 0;

  function rand(a, b) { return a + Math.random() * (b - a); }

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
      var b = bodies[i];
      b.x = Math.min(Math.max(b.r, b.x), W - b.r);
      b.y = Math.min(Math.max(b.r, b.y), H - b.r);
    }
  }

  function makeBody(x, y, r, shape, color) {
    return {
      x: x, y: y, vx: rand(-40, 40), vy: rand(0, 40),
      r: r, angle: rand(-0.3, 0.3), spin: rand(-2, 2),
      shape: shape, color: color, invMass: 1 / (r * r)
    };
  }

  function spawn(x, y) {
    var r = rand(15, 27);
    var ball = Math.random() < 0.22;
    var b = makeBody(x, y, r,
      ball ? "ball" : "crate",
      ball ? BALLS[(Math.random() * BALLS.length) | 0] : CRATES[(Math.random() * CRATES.length) | 0]);
    return b;
  }

  function seed() {
    bodies = [];
    var n = W < 420 ? 9 : 13;
    for (var i = 0; i < n; i++) {
      var b = spawn(rand(30, W - 30), rand(-H, H * 0.35));
      bodies.push(b);
    }
  }

  function dropAt(x, y) {
    if (bodies.length >= MAX_BODIES) bodies.shift();
    var b = spawn(x, y);
    b.vx = rand(-60, 60); b.vy = rand(-30, 40); b.spin = rand(-5, 5);
    bodies.push(b);
  }

  /* one fixed physics step */
  function step() {
    var i, j, b;

    for (i = 0; i < bodies.length; i++) {
      b = bodies[i];
      b.angle += b.spin * DT;
      b.spin *= 0.992;
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
      // crate vs crate (circle colliders)
      for (i = 0; i < bodies.length; i++) {
        for (j = i + 1; j < bodies.length; j++) {
          var a = bodies[i], c = bodies[j];
          var dx = c.x - a.x, dy = c.y - a.y;
          var dist = Math.hypot(dx, dy), min = a.r + c.r;
          if (dist >= min || dist === 0) continue;
          var nx = dx / dist, ny = dy / dist;
          var pen = min - dist, im = a.invMass + c.invMass;

          var corr = (Math.max(pen - SLOP, 0) / im) * CORRECT;
          a.x -= nx * corr * a.invMass; a.y -= ny * corr * a.invMass;
          c.x += nx * corr * c.invMass; c.y += ny * corr * c.invMass;

          var rvx = c.vx - a.vx, rvy = c.vy - a.vy;
          var vn = rvx * nx + rvy * ny;
          if (vn < 0) {
            var jn = -(1 + REST) * vn / im;
            a.vx -= jn * nx * a.invMass; a.vy -= jn * ny * a.invMass;
            c.vx += jn * nx * c.invMass; c.vy += jn * ny * c.invMass;
            // tangential friction + tumble
            var tx = -ny, ty = nx;
            var vt = (c.vx - a.vx) * tx + (c.vy - a.vy) * ty;
            var jt = -vt * FRICTION / im;
            a.vx -= jt * tx * a.invMass; a.vy -= jt * ty * a.invMass;
            c.vx += jt * tx * c.invMass; c.vy += jt * ty * c.invMass;
            var kick = vt * 0.03;
            a.spin -= kick; c.spin += kick;
          }
        }
      }
      // walls
      for (i = 0; i < bodies.length; i++) {
        b = bodies[i];
        if (b === held) continue;
        if (b.x < b.r) { b.x = b.r; if (b.vx < 0) b.vx = -b.vx * WALL_REST; b.spin *= 0.8; }
        else if (b.x > W - b.r) { b.x = W - b.r; if (b.vx > 0) b.vx = -b.vx * WALL_REST; b.spin *= 0.8; }
        if (b.y < b.r) { b.y = b.r; if (b.vy < 0) b.vy = -b.vy * WALL_REST; }
        else if (b.y > H - b.r) {
          b.y = H - b.r;
          if (b.vy > 0) b.vy = -b.vy * WALL_REST;
          b.vx *= 0.985;                       // floor friction
          b.spin = b.spin * 0.6 + (b.vx / b.r) * 0.4;  // roll to match motion
        }
      }
    }
  }

  function drawCrate(b) {
    var s = b.r * 1.5, in1 = s * 0.13;
    // ground shadow (axis-aligned, hard offset)
    roundRect(b.x - s / 2 + 3, b.y - s / 2 + 4, s, s, s * 0.16);
    ctx.fillStyle = "rgba(23,20,13,0.16)"; ctx.fill();

    ctx.save();
    ctx.translate(b.x, b.y); ctx.rotate(b.angle);
    roundRect(-s / 2, -s / 2, s, s, s * 0.16);
    ctx.fillStyle = b.color; ctx.fill();
    ctx.lineWidth = 2.4; ctx.strokeStyle = INK; ctx.stroke();
    // X brace
    var k = s * 0.5 - in1;
    ctx.lineWidth = 2; ctx.strokeStyle = "rgba(23,20,13,0.8)";
    ctx.beginPath();
    ctx.moveTo(-k, -k); ctx.lineTo(k, k);
    ctx.moveTo(k, -k); ctx.lineTo(-k, k);
    ctx.stroke();
    // inner plank frame
    ctx.lineWidth = 1.5; ctx.strokeStyle = "rgba(23,20,13,0.4)";
    roundRect(-s / 2 + in1, -s / 2 + in1, s - in1 * 2, s - in1 * 2, s * 0.08);
    ctx.stroke();
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
    for (var i = 0; i < bodies.length; i++) {
      if (bodies[i].shape === "ball") drawBall(bodies[i]);
      else drawCrate(bodies[i]);
    }
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

  /* ---------- Pointer ---------- */
  function pt(e) {
    var rect = canvas.getBoundingClientRect();
    return {
      x: (e.touches ? e.touches[0].clientX : e.clientX) - rect.left,
      y: (e.touches ? e.touches[0].clientY : e.clientY) - rect.top
    };
  }
  function onDown(e) {
    var p = pt(e); pointer.x = p.x; pointer.y = p.y; pointer.active = true;
    interacted = true; hideHint();
    var best = null, bestD = Infinity;
    for (var i = 0; i < bodies.length; i++) {
      var b = bodies[i], d = Math.hypot(b.x - p.x, b.y - p.y);
      if (d <= b.r + 6 && d < bestD) { best = b; bestD = d; }
    }
    if (best) { held = best; heldSavedInv = best.invMass; best.invMass = 0; lastHeldX = best.x; }
    else dropAt(p.x, p.y);
    e.preventDefault();
  }
  function onMove(e) { if (pointer.active) { var p = pt(e); pointer.x = p.x; pointer.y = p.y; e.preventDefault(); } }
  function onUp() {
    pointer.active = false;
    if (held) {
      held.invMass = heldSavedInv;
      held.spin = Math.max(-MAXSPIN, Math.min(MAXSPIN, -held.vx / held.r * 0.4)); // tumble with the throw
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
    gravBtn.textContent = "GRAVITY: " + (gravityOn ? "ON" : "OFF");
    if (!gravityOn) for (var i = 0; i < bodies.length; i++) bodies[i].vy -= 120;
    interacted = true; hideHint();
  });

  /* ---------- Lifecycle ---------- */
  resize(); seed();
  window.addEventListener("resize", resize);
  if ("IntersectionObserver" in window) {
    new IntersectionObserver(function (en) { if (en[0].isIntersecting) start(); else stop(); }, { threshold: 0.05 }).observe(canvas);
  } else { start(); }
  document.addEventListener("visibilitychange", function () { if (document.hidden) stop(); else start(); });
  setTimeout(function () { if (!interacted) hideHint(); }, 6000);
})();
