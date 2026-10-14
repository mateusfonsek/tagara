"""Builds Liquid Glass icon candidates as Icon Composer bundles and renders them with ictool.

Each concept is a few flat SVG layers; the glass, light and depth come from the system renderer.
Usage: python3 build.py   (outputs <concept>.icon and render/<concept>-<mode>.png)
"""
import json
import pathlib
import shutil
import subprocess

HERE = pathlib.Path(__file__).parent
ICTOOL = "/Applications/Xcode.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool"

WHITE = "srgb:1,1,1,1"
VIOLET = "srgb:0.780,0.635,0.925,1"  # carimbo, light variant (#C7A2EC)
VIOLET_DEEP = "srgb:0.357,0.165,0.525,1"  # carimbo (#5B2A86)


def svg(body: str) -> str:
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">{body}</svg>'


def gradient(top: str, bottom: str) -> dict:
    return {"linear-gradient": [top, bottom], "orientation": {"start": {"x": 0.5, "y": 0}, "stop": {"x": 0.5, "y": 1}}}


GRAPHITE_BG = gradient("srgb:0.235,0.255,0.224,1", "srgb:0.110,0.122,0.106,1")
VIOLET_BG = gradient("srgb:0.455,0.243,0.651,1", "srgb:0.231,0.098,0.369,1")

WAVE = 'M232 512 C 282 512 292 402 342 402 C 392 402 402 622 452 622 C 502 622 512 362 562 362 C 612 362 622 572 672 572 C 702 572 712 512 742 512'

CONCEPTS = {
    # Three capsules, the middle one in ink: the shortest possible waveform.
    "tres-barras": [
        ("sides", svg('<rect x="292" y="402" width="104" height="220" rx="52" fill="#fff"/><rect x="628" y="402" width="104" height="220" rx="52" fill="#fff"/>'), WHITE),
        ("middle", svg('<rect x="460" y="272" width="104" height="480" rx="52" fill="#fff"/>'), VIOLET),
    ],
    # Minimal speech bubble: a circle with its bottom-left corner made square.
    "bolha-canto": [
        ("bubble", svg('<path d="M232 512 A 280 280 0 1 1 512 792 L 232 792 Z" fill="#fff"/>'), WHITE),
        ("dot", svg('<circle cx="512" cy="512" r="72" fill="#fff"/>'), VIOLET_DEEP),
    ],
    # A single speech arc and its source.
    "ponto-arco": [
        ("arc", svg('<path d="M584 312 A 200 200 0 0 1 584 712" fill="none" stroke="#fff" stroke-width="104" stroke-linecap="round"/>'), None),
        ("dot", svg('<circle cx="424" cy="512" r="88" fill="#fff"/>'), VIOLET),
    ],
    # Typing indicator: someone is about to say something.
    "reticencias": [
        ("dots", svg('<circle cx="312" cy="512" r="76" fill="#fff"/><circle cx="512" cy="512" r="76" fill="#fff"/>'), WHITE),
        ("last", svg('<circle cx="712" cy="512" r="76" fill="#fff"/>'), VIOLET),
    ],
    # One open quote mark, as a single bold shape.
    "aspa-unica": [
        ("quote", svg('<path d="M372 600 C 372 420 452 300 612 236 L 652 300 C 560 352 524 418 524 470 C 610 470 664 530 664 606 C 664 690 598 752 518 752 C 432 752 372 690 372 600 Z" fill="#fff"/>'), VIOLET),
    ],
}

BACKGROUNDS = {"grafite": GRAPHITE_BG}


def layer(name: str, color) -> dict:
    """color=None keeps the SVG's own paint (needed for stroked paths, which a fill would flood)."""
    entry = {"image-name": f"{name}.svg", "name": name, "glass": True}
    if color is not None:
        entry["fill"] = {"solid": color}
    return entry


def manifest(layers, bg) -> dict:
    groups = []
    # Icon Composer lists groups front to back; the last layer drawn is the topmost mark.
    for i, (name, _, color) in enumerate(reversed(layers)):
        groups.append({
            "name": name,
            "layers": [layer(name, color)],
            "shadow": {"kind": "neutral", "opacity": 0.5},
            "specular": i == 0,
            "translucency": {"enabled": True, "value": 0.25 if i == 0 else 0.4},
            "lighting": "individual",
        })
    return {
        "fill": bg,
        "groups": groups,
        "supported-platforms": {"squares": "shared"},
    }


def build():
    render = HERE / "render"
    render.mkdir(exist_ok=True)
    for concept, layers in CONCEPTS.items():
        for bg_name, bg in BACKGROUNDS.items():
            name = f"{concept}-{bg_name}"
            bundle = HERE / f"{name}.icon"
            shutil.rmtree(bundle, ignore_errors=True)
            (bundle / "Assets").mkdir(parents=True)
            for layer_name, content, _ in layers:
                (bundle / "Assets" / f"{layer_name}.svg").write_text(content)
            (bundle / "icon.json").write_text(json.dumps(manifest(layers, bg), indent=2))
            for rendition in ("Default", "Dark"):
                out = render / f"{name}-{rendition.lower()}.png"
                subprocess.run([ICTOOL, str(bundle), "--export-image", "--output-file", str(out),
                                "--platform", "macOS", "--rendition", rendition,
                                "--width", "512", "--height", "512", "--scale", "1"], check=True)
            print("ok", name)


if __name__ == "__main__":
    build()
