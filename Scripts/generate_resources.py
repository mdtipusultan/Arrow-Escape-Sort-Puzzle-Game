#!/usr/bin/env python3
"""Generate Pathloom levels, sounds, and color assets."""
from __future__ import annotations

import json
import math
import random
import struct
import wave
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "Pathloom" / "Resources" / "Assets.xcassets"
SOUNDS = ROOT / "Pathloom" / "Resources" / "Sounds"
LEVELS = ROOT / "Pathloom" / "Resources" / "Levels.json"

DIRS = {
    "up": (-1, 0),
    "down": (1, 0),
    "left": (0, -1),
    "right": (0, 1),
}


def path_clear(row, col, direction, size, occupied):
    dr, dc = DIRS[direction]
    r, c = row + dr, col + dc
    while 0 <= r < size and 0 <= c < size:
        if (r, c) in occupied:
            return False
        r += dr
        c += dc
    return True


def can_escape(arrow, occupied, size):
    return path_clear(arrow["row"], arrow["column"], arrow["direction"], size, occupied)


def solve(level):
    arrows = {a["id"]: a for a in level["arrows"]}
    ids = sorted(arrows)
    index = {i: n for n, i in enumerate(ids)}
    start = (1 << len(ids)) - 1
    seen = {start}
    q = deque([(start, [])])
    while q:
        state, path = q.popleft()
        if state == 0:
            return path
        remaining = [i for i in ids if state & (1 << index[i])]
        occupied = {(arrows[i]["row"], arrows[i]["column"]): i for i in remaining}
        for i in remaining:
            a = arrows[i]
            if not can_escape(a, occupied, level["gridSize"]):
                continue
            nxt = state & ~(1 << index[i])
            if nxt in seen:
                continue
            seen.add(nxt)
            q.append((nxt, path + [i]))
    return None


def spec(level_id: int):
    if level_id == 1:
        return 3, 1, "tutorial"
    if level_id <= 10:
        size = 3 if level_id <= 5 else 4
        count = min(2 + (level_id // 2), size * size - 1)
        return size, count, "easy"
    if level_id <= 25:
        size = 4 if level_id <= 18 else 5
        count = min(4 + (level_id - 10) // 2, size * size - 2)
        return size, count, "easy" if level_id <= 18 else "medium"
    if level_id <= 50:
        size = 5 if level_id <= 38 else 6
        count = min(7 + (level_id - 25) // 3, size * size - 3)
        return size, count, "medium"
    if level_id <= 75:
        size = 6
        count = min(10 + (level_id - 51) // 3, 20)
        return size, count, "hard"
    size = 6 if level_id <= 90 else 7
    count = min(14 + (level_id - 76) // 2, size * size - 4)
    return size, min(count, 22), "expert"


def generate_level(level_id: int):
    size, count, difficulty = spec(level_id)
    seed = 17000 + level_id * 97
    rng = random.Random(seed)
    for attempt in range(80):
        occupied = {}
        arrows = []
        cells = [(r, c) for r in range(size) for c in range(size)]
        dirs = list(DIRS)
        for n in range(1, count + 1):
            rng.shuffle(cells)
            rng.shuffle(dirs)
            placed = False
            # Prefer blocking an existing arrow on later levels.
            preferred = []
            if arrows and rng.random() < min(0.25 + level_id / 140.0, 0.82):
                victim = rng.choice(arrows)
                dr, dc = DIRS[victim["direction"]]
                r, c = victim["row"] + dr, victim["column"] + dc
                while 0 <= r < size and 0 <= c < size:
                    if (r, c) not in occupied:
                        preferred.append((r, c))
                    r += dr
                    c += dc
            order = preferred + [c for c in cells if c not in preferred]
            for r, c in order:
                if (r, c) in occupied:
                    continue
                local_dirs = dirs[:]
                rng.shuffle(local_dirs)
                for d in local_dirs:
                    if path_clear(r, c, d, size, occupied):
                        occupied[(r, c)] = n
                        arrows.append({"id": n, "row": r, "column": c, "direction": d})
                        placed = True
                        break
                if placed:
                    break
            if not placed:
                break
        if len(arrows) != count:
            continue
        level = {
            "id": level_id,
            "gridSize": size,
            "parMoves": count,
            "difficulty": difficulty,
            "seed": seed + attempt,
            "arrows": arrows,
        }
        if solve(level):
            return level
    raise RuntimeError(f"Failed to generate level {level_id}")


def write_wav(path: Path, samples, sr=44100):
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        frames = bytearray()
        for s in samples:
            v = max(-0.98, min(0.98, s))
            frames += struct.pack("<h", int(v * 32767))
        w.writeframes(bytes(frames))


def env(i, n, a=0.02, r=0.2):
    t = i / max(n - 1, 1)
    if t < a:
        return t / a
    if t > 1 - r:
        return max(0.0, (1 - t) / r)
    return 1.0


def tone(freq, dur, sr=44100, vol=0.35, wave_kind="sine"):
    n = int(sr * dur)
    out = []
    for i in range(n):
        t = i / sr
        if wave_kind == "sine":
            s = math.sin(2 * math.pi * freq * t)
        elif wave_kind == "tri":
            s = 2 * abs(2 * ((t * freq) % 1) - 1) - 1
        else:
            s = 1.0 if (t * freq) % 1 < 0.5 else -1.0
        out.append(s * vol * env(i, n))
    return out


def sweep(f0, f1, dur, sr=44100, vol=0.3):
    n = int(sr * dur)
    out = []
    for i in range(n):
        t = i / sr
        f = f0 + (f1 - f0) * (i / max(n - 1, 1))
        out.append(math.sin(2 * math.pi * f * t) * vol * env(i, n, 0.01, 0.35))
    return out


def mix(*tracks):
    n = max(len(t) for t in tracks)
    out = [0.0] * n
    for t in tracks:
        for i, v in enumerate(t):
            out[i] += v
    peak = max(abs(x) for x in out) or 1
    if peak > 0.95:
        out = [x * 0.95 / peak for x in out]
    return out


def make_sounds():
    SOUNDS.mkdir(parents=True, exist_ok=True)
    write_wav(SOUNDS / "arrowTap.wav", tone(880, 0.05, vol=0.22, wave_kind="tri"))
    write_wav(SOUNDS / "arrowMove.wav", sweep(420, 920, 0.28, vol=0.32))
    write_wav(SOUNDS / "arrowBlocked.wav", mix(tone(160, 0.09, vol=0.28), tone(120, 0.09, vol=0.18, wave_kind="tri")))
    write_wav(
        SOUNDS / "levelComplete.wav",
        mix(tone(523.25, 0.18, vol=0.22), [0] * 2000 + tone(659.25, 0.18, vol=0.22), [0] * 4000 + tone(783.99, 0.32, vol=0.26)),
    )
    write_wav(SOUNDS / "buttonTap.wav", tone(740, 0.04, vol=0.18, wave_kind="tri"))
    write_wav(SOUNDS / "levelUnlock.wav", mix(tone(392, 0.12, vol=0.2), [0] * 1800 + tone(587, 0.2, vol=0.22)))
    write_wav(SOUNDS / "onboardingNext.wav", tone(640, 0.07, vol=0.2))

    sr = 44100
    dur = 8.0
    n = int(sr * dur)
    music = []
    for i in range(n):
        t = i / sr
        pad = (
            0.12 * math.sin(2 * math.pi * 196 * t)
            + 0.08 * math.sin(2 * math.pi * 246.94 * t)
            + 0.05 * math.sin(2 * math.pi * 293.66 * t)
        )
        breath = 0.5 + 0.5 * math.sin(2 * math.pi * t / dur)
        music.append(pad * 0.35 * breath)
    write_wav(SOUNDS / "musicLoop.wav", music)


def colorset(name, light, dark):
    folder = ASSETS / f"{name}.colorset"
    folder.mkdir(parents=True, exist_ok=True)
    def comp(rgb):
        return {"red": f"{rgb[0]:.3f}", "green": f"{rgb[1]:.3f}", "blue": f"{rgb[2]:.3f}", "alpha": "1.000"}
    data = {
        "colors": [
            {"idiom": "universal", "color": {"color-space": "srgb", "components": comp(light)}},
            {
                "appearances": [{"appearance": "luminosity", "value": "dark"}],
                "idiom": "universal",
                "color": {"color-space": "srgb", "components": comp(dark)},
            },
        ],
        "info": {"author": "xcode", "version": 1},
    }
    (folder / "Contents.json").write_text(json.dumps(data, indent=2))


def make_assets():
    ASSETS.mkdir(parents=True, exist_ok=True)
    (ASSETS / "Contents.json").write_text(json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2))
    colors = {
        "BackgroundColor": ((0.957, 0.941, 0.902), (0.086, 0.078, 0.071)),
        "BoardColor": ((1.0, 0.992, 0.973), (0.137, 0.125, 0.114)),
        "BrandPrimary": ((0.145, 0.408, 0.408), (0.42, 0.73, 0.69)),
        "BrandSecondary": ((0.769, 0.471, 0.353), (0.90, 0.62, 0.50)),
        "AccentColor": ((0.910, 0.659, 0.220), (0.95, 0.76, 0.38)),
        "SuccessColor": ((0.290, 0.608, 0.431), (0.45, 0.78, 0.60)),
        "WarningColor": ((0.851, 0.420, 0.298), (0.95, 0.55, 0.42)),
        "TextColor": ((0.110, 0.102, 0.090), (0.96, 0.94, 0.90)),
        "MutedTextColor": ((0.420, 0.396, 0.376), (0.70, 0.66, 0.62)),
        "CardColor": ((1.0, 0.996, 0.988), (0.16, 0.145, 0.133)),
        "DividerColor": ((0.855, 0.827, 0.784), (0.28, 0.25, 0.22)),
    }
    for name, pair in colors.items():
        colorset(name, *pair)
    accent = ASSETS / "AccentColor.colorset"
    accent.mkdir(parents=True, exist_ok=True)
    (accent / "Contents.json").write_text(
        json.dumps(
            {
                "colors": [
                    {
                        "idiom": "universal",
                        "color": {
                            "color-space": "srgb",
                            "components": {"red": "0.145", "green": "0.408", "blue": "0.408", "alpha": "1.000"},
                        },
                    }
                ],
                "info": {"author": "xcode", "version": 1},
            },
            indent=2,
        )
    )
    icon = ASSETS / "AppIcon.appiconset"
    icon.mkdir(parents=True, exist_ok=True)
    (icon / "Contents.json").write_text(
        json.dumps(
            {
                "images": [{"filename": "AppIcon.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}],
                "info": {"author": "xcode", "version": 1},
            },
            indent=2,
        )
    )


def make_levels():
    levels = [generate_level(i) for i in range(1, 101)]
    LEVELS.parent.mkdir(parents=True, exist_ok=True)
    LEVELS.write_text(json.dumps({"levels": levels}, indent=2))
    unsolved = [lv["id"] for lv in levels if solve(lv) is None]
    if unsolved:
        raise SystemExit(f"Unsolvable levels: {unsolved}")
    print(f"Wrote {len(levels)} solvable levels")


if __name__ == "__main__":
    make_assets()
    make_sounds()
    make_levels()
    print("Resources generated")
