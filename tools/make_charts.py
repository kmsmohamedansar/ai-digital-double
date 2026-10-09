"""Render the case-study charts from data/timeline.json as standalone SVGs.

Usage: python3 tools/make_charts.py   (writes charts/*.svg)
Stdlib only, so it runs anywhere without installing anything.
"""
import json
import os
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = json.load(open(os.path.join(ROOT, "data", "timeline.json")))
OUT = os.path.join(ROOT, "charts")
os.makedirs(OUT, exist_ok=True)

# Verdict -> colour. One hue per outcome, validated for contrast on both
# the light and dark GitHub themes (mid-tone fills, text uses currentColor).
VERDICT_COLOURS = {
    "dead end": "#d1495b",
    "partial": "#edae49",
    "useful as measurement": "#8d6cc8",
    "best likeness, wrong format": "#00798c",
    "shipped": "#30a46c",
}
FONT = "font-family='-apple-system, Segoe UI, Helvetica, Arial, sans-serif'"


def minutes(hhmm):
    h, m = hhmm.split(":")
    return int(h) * 60 + int(m)


def svg(width, height, body):
    style = (
        "<style>text{fill:#57606a} .t{fill:#24292f;font-weight:600}"
        "@media (prefers-color-scheme: dark){text{fill:#9aa4ae} .t{fill:#e6edf3} .g{stroke:#30363d}}</style>"
    )
    return (
        f"<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 {width} {height}' width='{width}' height='{height}' {FONT}>"
        f"{style}{body}</svg>"
    )


def timeline_chart():
    stages = DATA["stages"]
    t0 = min(minutes(s["start"]) for s in stages)
    t1 = max(minutes(s["end"]) for s in stages)
    left, right, top, row = 300, 30, 46, 30
    width = 760
    plot_w = width - left - right
    height = top + row * len(stages) + 80
    x = lambda t: left + (t - t0) / (t1 - t0) * plot_w
    parts = [f"<text class='t' x='20' y='26' font-size='16'>Nine approaches in one day, {stages[0]['start']}–{stages[-1]['end']}</text>"]
    # hour gridlines
    for t in range((t0 // 60 + 1) * 60, t1 + 1, 60):
        parts.append(f"<line class='g' x1='{x(t):.1f}' x2='{x(t):.1f}' y1='{top - 6}' y2='{top + row * len(stages)}' stroke='#d0d7de' stroke-dasharray='3 3'/>")
        parts.append(f"<text x='{x(t):.1f}' y='{top + row * len(stages) + 18}' font-size='11' text-anchor='middle'>{t // 60}:00</text>")
    for i, s in enumerate(stages):
        y = top + i * row
        a, b = minutes(s["start"]), minutes(s["end"])
        colour = VERDICT_COLOURS.get(s["verdict"], "#6e7781")
        parts.append(f"<text x='{left - 10}' y='{y + 17}' font-size='12' text-anchor='end'>{i + 1}. {s['title']}</text>")
        parts.append(f"<rect x='{x(a):.1f}' y='{y + 5}' width='{max(x(b) - x(a), 3):.1f}' height='{row - 10}' rx='3' fill='{colour}'><title>{s['title']}: {s['verdict']}</title></rect>")
    # legend
    lx, ly = left, top + row * len(stages) + 38
    for label, colour in VERDICT_COLOURS.items():
        parts.append(f"<rect x='{lx}' y='{ly - 9}' width='10' height='10' rx='2' fill='{colour}'/>")
        parts.append(f"<text x='{lx + 14}' y='{ly}' font-size='11'>{label}</text>")
        lx += 14 + len(label) * 6.2 + 18
        if lx > width - 160:
            lx, ly = left, ly + 18
    return svg(width, height, "".join(parts))


def outcomes_chart():
    counts = Counter(s["verdict"] for s in DATA["stages"])
    order = [v for v in VERDICT_COLOURS if v in counts]
    left, top, bar_h, gap, width = 230, 46, 22, 10, 620
    unit = (width - left - 60) / max(counts.values())
    height = top + len(order) * (bar_h + gap) + 10
    parts = ["<text class='t' x='20' y='26' font-size='16'>How each approach ended</text>"]
    for i, v in enumerate(order):
        y = top + i * (bar_h + gap)
        parts.append(f"<text x='{left - 10}' y='{y + 15}' font-size='12' text-anchor='end'>{v}</text>")
        parts.append(f"<rect x='{left}' y='{y}' width='{counts[v] * unit:.1f}' height='{bar_h}' rx='3' fill='{VERDICT_COLOURS[v]}'/>")
        parts.append(f"<text x='{left + counts[v] * unit + 8:.1f}' y='{y + 15}' font-size='12'>{counts[v]}</text>")
    return svg(width, height, "".join(parts))


def time_chart():
    stages = DATA["stages"]
    mins = [(f"{i + 1}. {s['title']}", minutes(s["end"]) - minutes(s["start"]), VERDICT_COLOURS.get(s["verdict"], "#6e7781")) for i, s in enumerate(stages)]
    left, top, bar_h, gap, width = 300, 46, 18, 8, 760
    unit = (width - left - 70) / max(m for _, m, _ in mins)
    height = top + len(mins) * (bar_h + gap) + 10
    total = sum(m for _, m, _ in mins)
    parts = [f"<text class='t' x='20' y='26' font-size='16'>Where the time went ({total // 60} h {total % 60} min of hands-on work)</text>"]
    for i, (name, m, colour) in enumerate(mins):
        y = top + i * (bar_h + gap)
        parts.append(f"<text x='{left - 10}' y='{y + 13}' font-size='12' text-anchor='end'>{name}</text>")
        parts.append(f"<rect x='{left}' y='{y}' width='{m * unit:.1f}' height='{bar_h}' rx='3' fill='{colour}'/>")
        parts.append(f"<text x='{left + m * unit + 8:.1f}' y='{y + 13}' font-size='12'>{m} min</text>")
    return svg(width, height, "".join(parts))


for name, fn in (("timeline", timeline_chart), ("outcomes", outcomes_chart), ("time", time_chart)):
    with open(os.path.join(OUT, f"{name}.svg"), "w") as f:
        f.write(fn())
    print(f"charts/{name}.svg")
