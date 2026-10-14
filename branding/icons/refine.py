"""Refinement round for the chosen 'three bars' icon. Reuses build.py's bundle writer.

Usage: python3 refine.py   (outputs tb-*.icon and render/tb-*-<mode>.png)
"""
import json
import shutil
import subprocess

import build
from build import HERE, ICTOOL, WHITE, VIOLET, svg, gradient

VIOLET_GLOW = {"linear-gradient": ["srgb:0.847,0.749,0.957,1", "srgb:0.616,0.420,0.851,1"],
               "orientation": {"start": {"x": 0.5, "y": 0}, "stop": {"x": 0.5, "y": 1}}}
GRAPHITE = build.GRAPHITE_BG
GRAPHITE_VIOLET = gradient("srgb:0.212,0.224,0.204,1", "srgb:0.169,0.106,0.231,1")


def bars(w, heights, gap):
    """Three centered capsules; returns (sides_svg, middle_svg)."""
    total = 3 * w + 2 * gap
    x0 = 512 - total / 2
    xs = [x0, x0 + w + gap, x0 + 2 * (w + gap)]
    rect = lambda x, h: f'<rect x="{x:.0f}" y="{512 - h / 2:.0f}" width="{w}" height="{h}" rx="{w / 2:.0f}" fill="#fff"/>'
    return svg(rect(xs[0], heights[0]) + rect(xs[2], heights[2])), svg(rect(xs[1], heights[1]))


VARIANTS = {
    # A: the chosen icon, scaled up to fill the canvas like the references.
    "tb-a-maior": dict(w=120, heights=(270, 560, 270), gap=64, mid=VIOLET, bg=GRAPHITE),
    # B: uneven sides, like a real voice level rather than a symbol.
    "tb-b-voz": dict(w=120, heights=(250, 560, 370), gap=64, mid=VIOLET, bg=GRAPHITE),
    # C: chunkier bars, tighter gaps: a bolder mark at small sizes.
    "tb-c-robusta": dict(w=150, heights=(300, 560, 300), gap=52, mid=VIOLET, bg=GRAPHITE),
    # D: middle bar lit from within with a violet gradient.
    "tb-d-luz": dict(w=120, heights=(270, 560, 270), gap=64, mid=VIOLET_GLOW, bg=GRAPHITE),
    # E: graphite that sinks into violet at the bottom.
    "tb-e-fundo": dict(w=120, heights=(270, 560, 270), gap=64, mid=VIOLET, bg=GRAPHITE_VIOLET),
    # F: all three in glass white; the violet lives only in the background.
    "tb-f-mono": dict(w=120, heights=(270, 560, 270), gap=64, mid=WHITE, bg=GRAPHITE_VIOLET),
}


def fill(color):
    return color if isinstance(color, dict) else {"solid": color}


def main():
    render = HERE / "render"
    render.mkdir(exist_ok=True)
    for name, v in VARIANTS.items():
        sides, middle = bars(v["w"], v["heights"], v["gap"])
        bundle = HERE / f"{name}.icon"
        shutil.rmtree(bundle, ignore_errors=True)
        (bundle / "Assets").mkdir(parents=True)
        (bundle / "Assets" / "sides.svg").write_text(sides)
        (bundle / "Assets" / "middle.svg").write_text(middle)
        manifest = {
            "fill": v["bg"],
            "groups": [
                {"name": "middle", "layers": [{"image-name": "middle.svg", "name": "middle", "glass": True, "fill": fill(v["mid"])}],
                 "shadow": {"kind": "neutral", "opacity": 0.5}, "specular": True,
                 "translucency": {"enabled": True, "value": 0.25}, "lighting": "individual"},
                {"name": "sides", "layers": [{"image-name": "sides.svg", "name": "sides", "glass": True, "fill": {"solid": WHITE}}],
                 "shadow": {"kind": "neutral", "opacity": 0.5}, "specular": False,
                 "translucency": {"enabled": True, "value": 0.4}, "lighting": "individual"},
            ],
            "supported-platforms": {"squares": "shared"},
        }
        (bundle / "icon.json").write_text(json.dumps(manifest, indent=2))
        for rendition in ("Default", "Dark", "TintedDark"):
            out = render / f"{name}-{rendition.lower()}.png"
            subprocess.run([ICTOOL, str(bundle), "--export-image", "--output-file", str(out), "--platform", "macOS",
                            "--rendition", rendition, "--width", "512", "--height", "512", "--scale", "1"],
                           check=True, capture_output=True)
        print("ok", name)


if __name__ == "__main__":
    main()
