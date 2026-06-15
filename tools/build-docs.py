#!/usr/bin/env python3
"""Render docs/*.md into styled, self-contained HTML pages under website/docs/.

Dependency-free on purpose: OXT/web sessions and CI may have no network for
pip, so this ships its own small Markdown converter covering exactly what the
Box2Dxt docs use (ATX headings with GitHub-style anchors, fenced code, GFM
pipe tables, blockquotes, nested lists, inline code/links/bold/italic, rules).

Run after editing any doc:   python3 tools/build-docs.py
The site links to these pages instead of raw .md files on GitHub.
"""

import html
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "docs"
OUT = ROOT / "website" / "docs"
GH = "https://github.com/SethMorrowSoftware/Box2Dxt"

# Host only the approachable, user-facing docs. The deeper/internal material
# (raw API, architecture, build-from-source, design/roadmap) stays on GitHub —
# links to those .md files are rewritten to GitHub automatically.
DOCS = [
    ("getting-started", "Getting started", "Install the library and build your first draggable scene."),
    ("kit-guide",       "Kit guide",       "The friendly b2k… layer, taught step by step."),
    ("kit-reference",   "Kit reference",   "Every b2k… call, one line each — keep it open while you build."),
]
TITLES = {k: (t, d) for k, t, d in DOCS}

# Shown on the manual overview as "going deeper" — these live on GitHub.
EXTERNAL = [
    ("API reference",    "The raw b2… extension surface.",        "api-reference.md"),
    ("Architecture",     "How the three layers fit together.",    "architecture.md"),
    ("Game engine spec", "The Game Kit design, in depth.",        "game-engine-spec.md"),
    ("Building",         "Compile the native library yourself.",  "building.md"),
    ("Expansion prep",   "The internal roadmap & intake plan.",   "expansion-prep.md"),
]


# --------------------------------------------------------------------------- #
#  link rewriting: keep doc-to-doc links in-site, send everything else to GH
# --------------------------------------------------------------------------- #
def rewrite_href(href):
    href = href.strip()
    if href.startswith("#") or href.startswith("mailto:") or re.match(r"^https?://", href):
        return href
    path, _, frag = href.partition("#")
    frag = ("#" + frag) if frag else ""

    m = re.match(r"^(?:\./)?([\w-]+)\.md$", path)
    if m:
        name = m.group(1)
        if name in TITLES:
            return f"{name}.html{frag}"
        return f"{GH}/blob/main/docs/{name}.md{frag}"

    if path.startswith(".."):
        rel = re.sub(r"^(\.\./)+", "", path)
        if rel.rstrip("/") == "releases":
            return f"{GH}/releases{frag}"
        if path.endswith("/") or "." not in rel.split("/")[-1]:
            return f"{GH}/tree/main/{rel.rstrip('/')}{frag}"
        return f"{GH}/blob/main/{rel}{frag}"

    if path:  # any other repo-relative path lives under docs/
        return f"{GH}/blob/main/docs/{path}{frag}"
    return href


# --------------------------------------------------------------------------- #
#  inline (runs on prose, table cells, list items, headings)
# --------------------------------------------------------------------------- #
def inline(text):
    spans = []

    def stash(m):
        spans.append(html.escape(m.group(1)))
        return f"\x00{len(spans) - 1}\x00"

    text = re.sub(r"`([^`]+)`", stash, text)          # protect inline code
    text = html.escape(text, quote=False)             # escape the rest
    text = re.sub(r"!\[([^\]]*)\]\(([^)\s]+)[^)]*\)",
                  lambda m: f'<img alt="{m.group(1)}" src="{rewrite_href(m.group(2))}">', text)
    text = re.sub(r"\[([^\]]+)\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)",
                  lambda m: f'<a href="{rewrite_href(m.group(2))}">{m.group(1)}</a>', text)
    text = re.sub(r"&lt;(https?://[^&\s]+)&gt;",
                  lambda m: f'<a href="{m.group(1)}">{m.group(1)}</a>', text)
    text = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", text)       # bold may wrap italics
    text = re.sub(r"__(.+?)__", r"<strong>\1</strong>", text)
    text = re.sub(r"(?<![\w*])\*(?!\s)([^*\n]+?)\*(?![\w*])", r"<em>\1</em>", text)
    text = re.sub(r"(?<![\w_])_(?!\s)([^_\n]+?)_(?![\w_])", r"<em>\1</em>", text)
    text = re.sub(r"\x00(\d+)\x00", lambda m: f"<code>{spans[int(m.group(1))]}</code>", text)
    return text


def slugify(text, used):
    t = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)   # link -> its text
    t = re.sub(r"[`*_]", "", t).strip().lower()
    t = re.sub(r"[^\w\s-]", "", t)
    t = re.sub(r"\s", "-", t)          # GitHub does NOT collapse: "a & b" -> "a--b"
    t = t.strip("-")
    base, k = t, 1
    while t in used:
        t = f"{base}-{k}"
        k += 1
    used.add(t)
    return t


# --------------------------------------------------------------------------- #
#  block parser
# --------------------------------------------------------------------------- #
ITEM_RE = re.compile(r"^(\s*)([-*+]|\d+[.)])\s+(.*)$")


def is_table_sep(s):
    s = s.strip()
    return bool(s) and set(s) <= set("|:- ") and "-" in s and "|" in s


def split_row(line):
    line = line.strip()
    if line.startswith("|"):
        line = line[1:]
    if line.endswith("|"):
        line = line[:-1]
    cells = re.split(r"(?<!\\)\|", line)
    return [c.strip().replace("\\|", "|") for c in cells]


def render_list(lines):
    """lines: the block belonging to one list (possibly nested)."""
    indents = [len(re.match(r"\s*", l).group()) for l in lines if l.strip()]
    if not indents:
        return ""
    base = min(indents)
    items, cur, sub = [], None, []
    for l in lines:
        m = ITEM_RE.match(l)
        if m and len(m.group(1)) == base:
            if cur is not None:
                cur["sub"] = sub
                items.append(cur)
                sub = []
            cur = {"marker": m.group(2), "text": m.group(3)}
        else:
            sub.append(l)
    if cur is not None:
        cur["sub"] = sub
        items.append(cur)

    ordered = bool(re.match(r"\d+[.)]", items[0]["marker"]))
    tag = "ol" if ordered else "ul"
    out = [f"<{tag}>"]
    for it in items:
        subblock = [s[base:] if len(s) >= base else s for s in it["sub"]]
        # split wrapped continuation text (before any nested list) from nested items
        cont_lines, nested_lines, seen = [], [], False
        for s in subblock:
            if ITEM_RE.match(s):
                seen = True
            (nested_lines if seen else cont_lines).append(s)
        raw = it["text"]
        cont = " ".join(s.strip() for s in cont_lines if s.strip())
        if cont:                       # join so inline runs once (bold can wrap lines)
            raw = raw + " " + cont
        body = inline(raw)
        if any(ITEM_RE.match(s) for s in nested_lines):
            body += render_list(nested_lines)
        out.append(f"<li>{body}</li>")
    out.append(f"</{tag}>")
    return "\n".join(out)


def convert(md):
    lines = md.replace("\r\n", "\n").split("\n")
    n = len(lines)
    out, used = [], set()
    i = 0
    while i < n:
        line = lines[i]

        if not line.strip():
            i += 1
            continue

        # fenced code
        fence = re.match(r"^\s*(`{3,}|~{3,})(.*)$", line)
        if fence:
            marker = fence.group(1)[0]
            buf, i = [], i + 1
            while i < n and not re.match(rf"^\s*{re.escape(marker)}{{3,}}\s*$", lines[i]):
                buf.append(lines[i])
                i += 1
            i += 1  # skip closing fence
            code = html.escape("\n".join(buf))
            out.append(f'<pre><code>{code}</code></pre>')
            continue

        # heading
        h = re.match(r"^(#{1,6})\s+(.*?)\s*#*\s*$", line)
        if h:
            level = len(h.group(1))
            raw = h.group(2)
            sid = slugify(raw, used)
            out.append(f'<h{level} id="{sid}">{inline(raw)}</h{level}>')
            i += 1
            continue

        # horizontal rule
        if re.match(r"^\s*([-*_])(\s*\1){2,}\s*$", line):
            out.append("<hr>")
            i += 1
            continue

        # table
        if "|" in line and i + 1 < n and is_table_sep(lines[i + 1]):
            header = split_row(line)
            i += 2
            rows = []
            while i < n and lines[i].strip() and "|" in lines[i]:
                rows.append(split_row(lines[i]))
                i += 1
            thead = "".join(f"<th>{inline(c)}</th>" for c in header)
            tbody = ""
            for r in rows:
                r = (r + [""] * len(header))[:len(header)]
                tbody += "<tr>" + "".join(f"<td>{inline(c)}</td>" for c in r) + "</tr>"
            out.append(f'<div class="md-tablewrap"><table><thead><tr>{thead}'
                       f"</tr></thead><tbody>{tbody}</tbody></table></div>")
            continue

        # blockquote
        if re.match(r"^\s*>", line):
            buf = []
            while i < n and re.match(r"^\s*>", lines[i]):
                buf.append(re.sub(r"^\s*>\s?", "", lines[i]))
                i += 1
            out.append(f"<blockquote>{convert(chr(10).join(buf))}</blockquote>")
            continue

        # list
        if ITEM_RE.match(line):
            base = len(re.match(r"\s*", line).group())
            buf = []
            while i < n:
                l = lines[i]
                if not l.strip():
                    j = i + 1
                    if j < n and (ITEM_RE.match(lines[j]) or (lines[j][:1] == " " and lines[j].strip())):
                        buf.append(l)
                        i += 1
                        continue
                    break
                if ITEM_RE.match(l) or l.startswith(" "):
                    buf.append(l)
                    i += 1
                    continue
                break
            out.append(render_list(buf))
            continue

        # paragraph
        buf = []
        while i < n and lines[i].strip() and not re.match(r"^\s*(#{1,6}\s|>|```|~~~)", lines[i]) \
                and not ITEM_RE.match(lines[i]) \
                and not re.match(r"^\s*([-*_])(\s*\1){2,}\s*$", lines[i]) \
                and not ("|" in lines[i] and i + 1 < n and is_table_sep(lines[i + 1])):
            buf.append(lines[i].rstrip())
            i += 1
        out.append(f"<p>{inline(' '.join(buf))}</p>")

    return "\n".join(out)


# --------------------------------------------------------------------------- #
#  page templates
# --------------------------------------------------------------------------- #
CRATE = ('<svg width="0" height="0" style="position:absolute" aria-hidden="true"><symbol id="crate" '
         'viewBox="0 0 32 32"><rect x="3" y="3" width="26" height="26" rx="5" fill="#e8702a" '
         'stroke="#17140d" stroke-width="2.5"/><path d="M3 3l26 26M29 3L3 29" stroke="#17140d" '
         'stroke-width="2"/></symbol></svg>')


def menubar():
    return f"""<header class="menubar" id="top"><div class="wrap menubar-inner">
  <a class="brand" href="../index.html#top"><svg width="24" height="24" aria-hidden="true"><use href="#crate"/></svg> Box2D<b>xt</b></a>
  <nav class="menu-links" id="menuLinks" aria-label="Primary">
    <a href="../index.html#paste">One&nbsp;paste</a>
    <a href="../index.html#features">What&nbsp;you&nbsp;get</a>
    <a href="../index.html#how">How&nbsp;it&nbsp;works</a>
    <a href="../index.html#examples">Examples</a>
    <a href="index.html">Docs</a>
  </nav>
  <div class="menu-right"><a class="menu-ghost" href="{GH}" target="_blank" rel="noopener">GitHub</a></div>
  <button class="menu-toggle" id="menuToggle" aria-label="Menu" aria-expanded="false">MENU</button>
</div></header>"""


def sidebar(active):
    rows = ['<a href="index.html"%s>Overview</a>' % (' class="active"' if active == "index" else "")]
    for key, title, _ in DOCS:
        cls = ' class="active"' if key == active else ""
        rows.append(f'<a href="{key}.html"{cls}>{title}</a>')
    rows.append(f'<a class="doc-side-gh" href="{GH}/tree/main/docs" target="_blank" rel="noopener">Full docs on GitHub →</a>')
    return ('<aside class="doc-side"><div class="doc-side-inner"><span class="label">THE MANUAL</span>'
            + "\n".join(rows) + "</div></aside>")


FOOTER = f"""<footer class="footer"><div class="wrap footer-bottom" style="border-top:none;margin-top:0">
  <span>MIT licensed · Box2D © Erin Catto, also MIT</span>
  <a href="../index.html#top">BACK TO THE SITE ↑</a>
</div></footer>"""


def shell(title, desc, active, main_html):
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{html.escape(title)} — Box2Dxt docs</title>
<meta name="description" content="{html.escape(desc)}">
<meta name="color-scheme" content="light">
<link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Crect x='1' y='1' width='30' height='30' rx='6' fill='%23f1ece1' stroke='%2317140d' stroke-width='2'/%3E%3Crect x='7' y='7' width='18' height='18' rx='3' fill='%23e8702a' stroke='%2317140d' stroke-width='2'/%3E%3Cpath d='M7 7l18 18M25 7L7 25' stroke='%2317140d' stroke-width='1.5'/%3E%3C/svg%3E">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500;600&family=Silkscreen:wght@400;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="../styles.css">
</head>
<body>
{CRATE}
{menubar()}
{main_html}
{FOOTER}
<script src="../app.js"></script>
</body>
</html>
"""


def doc_page(key):
    title, desc = TITLES[key]
    body = convert((SRC / f"{key}.md").read_text(encoding="utf-8"))
    main = f"""<main class="doc-wrap">
{sidebar(key)}
<article class="win doc-win">
  <div class="win-bar"><span class="win-box"></span><span class="win-stripes"></span><span class="win-title">{key}.md</span><span class="win-box"></span></div>
  <div class="win-body prose">{body}</div>
</article>
</main>"""
    return shell(title, desc, key, main)


def index_page():
    nums = ["①", "②", "③"]
    cards = "\n".join(
        f'<a class="doc" href="{k}.html"><h4>{nums[i]} {t}</h4><p>{html.escape(d)}</p></a>'
        for i, (k, t, d) in enumerate(DOCS)
    )
    deeper = "\n".join(
        f'<li><a href="{GH}/blob/main/docs/{path}" target="_blank" rel="noopener">{t}</a> — {html.escape(d)}</li>'
        for t, d, path in EXTERNAL
    )
    main = f"""<main class="doc-wrap">
{sidebar("index")}
<article class="win doc-win">
  <div class="win-bar"><span class="win-box"></span><span class="win-stripes"></span><span class="win-title">the manual</span><span class="win-box"></span></div>
  <div class="win-body prose">
    <h1>The Box2Dxt manual</h1>
    <p>New here? You only need two things: <a href="getting-started.html">Getting started</a> to install Box2Dxt and drop your first body, then the <a href="kit-guide.html">Kit guide</a> to learn the rest. Keep the <a href="kit-reference.html">Kit reference</a> open while you build.</p>
    <div class="docs-grid docs-grid-3" style="margin-top:22px">{cards}</div>
    <h2>Going deeper</h2>
    <p>The low-level <code>b2…</code> API, the engine internals, and build-from-source notes are for the curious — they live on GitHub:</p>
    <ul>{deeper}</ul>
  </div>
</article>
</main>"""
    return shell("Documentation", "The Box2Dxt guides — install, learn the Kit, and a quick reference.", "index", main)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "index.html").write_text(index_page(), encoding="utf-8")
    n = 1
    for key, _, _ in DOCS:
        (OUT / f"{key}.html").write_text(doc_page(key), encoding="utf-8")
        n += 1
    print(f"Built {n} doc pages -> {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
