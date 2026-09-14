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


def solve(level, node_limit=80000):
    arrows = {a["id"]: a for a in level["arrows"]}
    ids = sorted(arrows)
    index = {i: n for n, i in enumerate(ids)}
    start = (1 << len(ids)) - 1
    seen = {start}
    q = deque([(start, [])])
    while q:
        if len(seen) > node_limit:
            return None
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
    """Steep curve: early teaching boards, late boards dense with long lock chains."""
    if level_id == 1:
        return 3, 1, "tutorial"
    if level_id <= 8:
        return 3, min(2 + (level_id - 1), 5), "easy"
    if level_id <= 16:
        return 4, 6 + (level_id - 9), "easy"
    if level_id <= 28:
        return 5, 10 + (level_id - 17) // 2, "medium"
    if level_id <= 45:
        return 6, 14 + (level_id - 29) // 2, "medium"
    if level_id <= 65:
        return 6, 18 + (level_id - 46) // 3, "hard"
    if level_id <= 82:
        return 7, 20 + (level_id - 66) // 3, "hard"
    size = 7 if level_id <= 92 else 8
    count = 22 + (level_id - 83) // 2
    cap = size * size - 6
    return size, min(count, cap, 24), "expert"


def count_free(arrows, size):
    occupied = {(a["row"], a["column"]) for a in arrows}
    return sum(1 for a in arrows if can_escape(a, occupied, size))


def longest_lock_chain(arrows, size):
    by_cell = {(a["row"], a["column"]): a["id"] for a in arrows}
    depends = {a["id"]: [] for a in arrows}
    for a in arrows:
        dr, dc = DIRS[a["direction"]]
        r, c = a["row"] + dr, a["column"] + dc
        while 0 <= r < size and 0 <= c < size:
            blocker = by_cell.get((r, c))
            if blocker is not None:
                depends[a["id"]].append(blocker)
                break
            r += dr
            c += dc
    memo = {}
    visiting = set()

    def depth(i):
        if i in memo:
            return memo[i]
        if i in visiting:
            return 1
        visiting.add(i)
        kids = depends[i]
        memo[i] = 1 + (max((depth(k) for k in kids), default=0) if kids else 0)
        visiting.remove(i)
        return memo[i]

    return max((depth(a["id"]) for a in arrows), default=1)


def playthrough_branching(level):
    arrows = {a["id"]: a for a in level["arrows"]}
    remaining = set(arrows)
    frees = []
    size = level["gridSize"]
    while remaining:
        occupied = {(arrows[i]["row"], arrows[i]["column"]) for i in remaining}
        open_ids = [i for i in remaining if can_escape(arrows[i], occupied, size)]
        if not open_ids:
            break
        frees.append(len(open_ids))
        remaining.remove(min(open_ids))
    if not frees:
        return 99.0, 99
    return sum(frees) / len(frees), min(frees)


def difficulty_score(level):
    arrows = level["arrows"]
    n = len(arrows)
    size = level["gridSize"]
    free0 = count_free(arrows, size)
    chain = longest_lock_chain(arrows, size)
    avg_free, min_free = playthrough_branching(level)
    blocked = n - free0
    return (
        blocked * 14
        + chain * 18
        + n * 3
        + size * 2
        - free0 * 22
        - avg_free * 10
        - min_free * 8
    )


def rotate_dir(direction, turns):
    order = ["up", "right", "down", "left"]
    return order[(order.index(direction) + turns) % 4]


def transform_level(level, turns, flip):
    size = level["gridSize"]
    arrows = []
    for a in level["arrows"]:
        r, c = a["row"], a["column"]
        if flip:
            c = size - 1 - c
            d = {"left": "right", "right": "left", "up": "up", "down": "down"}[a["direction"]]
        else:
            d = a["direction"]
        for _ in range(turns):
            r, c = c, size - 1 - r
            d = rotate_dir(d, 1)
        arrows.append({"id": a["id"], "row": r, "column": c, "direction": d})
    out = dict(level)
    out["arrows"] = arrows
    return out


def layout_key(level):
    return tuple(sorted((a["row"], a["column"], a["direction"]) for a in level["arrows"]))


def reverse_construct(size, count, rng, tightness):
    occupied = {}
    arrows = []

    def try_place(row, col, direction):
        if (row, col) in occupied:
            return False
        if not path_clear(row, col, direction, size, occupied):
            return False
        nid = len(arrows) + 1
        occupied[(row, col)] = nid
        arrows.append({"id": nid, "row": row, "column": col, "direction": direction})
        return True

    first_cells = [(r, c) for r in range(size) for c in range(size)]
    rng.shuffle(first_cells)
    placed_first = False
    for r, c in first_cells:
        dirs = list(DIRS)
        rng.shuffle(dirs)
        for d in dirs:
            if try_place(r, c, d):
                placed_first = True
                break
        if placed_first:
            break
    if not placed_first:
        return None

    empty = {(r, c) for r in range(size) for c in range(size)} - set(occupied)
    for _ in range(1, count):
        free_now = [a for a in arrows if can_escape(a, occupied, size)]
        block_hits = {}
        for victim in free_now:
            dr, dc = DIRS[victim["direction"]]
            r, c = victim["row"] + dr, victim["column"] + dc
            while 0 <= r < size and 0 <= c < size:
                if (r, c) not in occupied:
                    block_hits[(r, c)] = block_hits.get((r, c), 0) + 1
                r += dr
                c += dc

        candidates = list(block_hits)
        extras = list(empty)
        rng.shuffle(extras)
        candidates.extend(extras[: max(6, size)])

        scored = []
        dirs = list(DIRS)
        for r, c in candidates:
            if (r, c) in occupied:
                continue
            rng.shuffle(dirs)
            for d in dirs:
                if not path_clear(r, c, d, size, occupied):
                    continue
                interior = min(r, c, size - 1 - r, size - 1 - c)
                score = block_hits.get((r, c), 0) * 14 + interior * 2
                scored.append((score, r, c, d))
        if not scored:
            return None
        scored.sort(key=lambda x: x[0], reverse=True)
        window = max(1, int(len(scored) * max(0.06, 1.0 - tightness)))
        pick = scored[rng.randrange(window)]
        if not try_place(pick[1], pick[2], pick[3]):
            return None
        empty.discard((pick[1], pick[2]))
    if len(arrows) != count:
        return None
    return arrows


def jam_pattern(size, count, rng):
    """Fill lanes that all wait on a single crossing key."""
    occupied = {}
    arrows = []
    nid = 1

    def add(r, c, d):
        nonlocal nid
        if not (0 <= r < size and 0 <= c < size) or (r, c) in occupied:
            return False
        occupied[(r, c)] = nid
        arrows.append({"id": nid, "row": r, "column": c, "direction": d})
        nid += 1
        return True

    # Place the last-to-leave traffic first in reverse? We still need solvability.
    # Build reverse: key on the edge, then a crossing column, then a jammed row.
    key_col = rng.randint(1, size - 2)
    add(size - 1, key_col, "down")
    for r in range(size - 2, -1, -1):
        if nid > count:
            break
        add(r, key_col, rng.choice(["down", "left", "right"] if r > 0 else ["down"]))
        if not path_clear(arrows[-1]["row"], arrows[-1]["column"], arrows[-1]["direction"], size, occupied):
            arrows.pop()
            occupied.pop((r, key_col), None)
            nid -= 1
            add(r, key_col, "down")
    rows = list(range(size - 1))
    rng.shuffle(rows)
    for r in rows:
        if nid > count:
            break
        for c in range(size):
            if nid > count:
                break
            if (r, c) in occupied:
                continue
            d = "right" if c < key_col else "left"
            if c == key_col:
                continue
            if path_clear(r, c, d, size, occupied) or True:
                # may not be clear; only add if currently clear so reverse-order holds
                if path_clear(r, c, d, size, occupied):
                    add(r, c, d)
    if len(arrows) < count:
        cells = [(r, c) for r in range(size) for c in range(size) if (r, c) not in occupied]
        rng.shuffle(cells)
        for r, c in cells:
            if len(arrows) >= count:
                break
            dirs = list(DIRS)
            rng.shuffle(dirs)
            for d in dirs:
                if path_clear(r, c, d, size, occupied):
                    add(r, c, d)
                    break
    return arrows if len(arrows) == count else None


def handmade(level_id: int):
    if level_id == 1:
        return 3, "tutorial", [{"id": 1, "row": 1, "column": 0, "direction": "right"}]
    if level_id == 2:
        return 3, "easy", [
            {"id": 1, "row": 1, "column": 0, "direction": "right"},
            {"id": 2, "row": 1, "column": 2, "direction": "up"},
        ]
    if level_id == 3:
        return 3, "easy", [
            {"id": 1, "row": 2, "column": 0, "direction": "right"},
            {"id": 2, "row": 2, "column": 2, "direction": "up"},
            {"id": 3, "row": 0, "column": 2, "direction": "left"},
        ]
    if level_id == 4:
        return 3, "easy", [
            {"id": 1, "row": 1, "column": 0, "direction": "right"},
            {"id": 2, "row": 1, "column": 1, "direction": "right"},
            {"id": 3, "row": 1, "column": 2, "direction": "up"},
            {"id": 4, "row": 0, "column": 2, "direction": "left"},
        ]
    if level_id == 5:
        return 3, "easy", [
            {"id": 1, "row": 0, "column": 1, "direction": "down"},
            {"id": 2, "row": 1, "column": 0, "direction": "right"},
            {"id": 3, "row": 1, "column": 2, "direction": "down"},
            {"id": 4, "row": 2, "column": 1, "direction": "left"},
            {"id": 5, "row": 1, "column": 1, "direction": "down"},
        ]
    return None


def generate_level(level_id: int, seen: set):
    hand = handmade(level_id)
    if hand:
        size, difficulty, arrows = hand
        level = {
            "id": level_id,
            "gridSize": size,
            "parMoves": len(arrows),
            "difficulty": difficulty,
            "seed": 9000 + level_id,
            "arrows": arrows,
        }
        if not solve(level):
            raise RuntimeError(f"Handmade level {level_id} is unsolvable")
        seen.add(layout_key(level))
        return level

    size, count, difficulty = spec(level_id)
    seed = 41000 + level_id * 131
    rng = random.Random(seed)
    tightness = min(0.96, 0.48 + level_id / 105.0)
    attempts = 18 if level_id <= 16 else 28 if level_id <= 50 else 36
    best = None
    best_score = -10**9
    for attempt in range(attempts):
        if level_id > 20 and attempt % 5 == 0:
            arrows = jam_pattern(size, count, random.Random(seed + attempt * 17 + 3))
        else:
            arrows = reverse_construct(size, count, random.Random(seed + attempt * 19), tightness)
        if not arrows:
            continue
        if count_free(arrows, size) > (3 if level_id > 16 else 5):
            continue
        base = {
            "id": level_id,
            "gridSize": size,
            "parMoves": len(arrows),
            "difficulty": difficulty,
            "seed": seed + attempt,
            "arrows": arrows,
        }
        variant = transform_level(base, attempt % 4, attempt % 2 == 1)
        if layout_key(variant) in seen:
            continue
        if solve(variant) is None:
            continue
        free0 = count_free(variant["arrows"], size)
        chain = longest_lock_chain(variant["arrows"], size)
        if level_id > 12 and free0 > max(2, 4 - level_id // 30):
            continue
        if level_id > 40 and chain < 5:
            continue
        if level_id > 70 and chain < 7:
            continue
        score = difficulty_score(variant)
        if score > best_score:
            best_score = score
            best = variant
    if best is None:
        for attempt in range(80):
            arrows = reverse_construct(size, max(count - attempt // 20, 6), random.Random(seed + 9000 + attempt), 0.75)
            if not arrows:
                continue
            if count_free(arrows, size) > 4:
                continue
            level = {
                "id": level_id,
                "gridSize": size,
                "parMoves": len(arrows),
                "difficulty": difficulty,
                "seed": seed + 9000 + attempt,
                "arrows": arrows,
            }
            if solve(level):
                best = level
                break
    if best is None:
        raise RuntimeError(f"Failed to generate level {level_id}")
    seen.add(layout_key(best))
    return best


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
    seen = set()
    levels = []
    for i in range(1, 101):
        lv = generate_level(i, seen)
        levels.append(lv)
        print(
            f"L{i:03d} {lv['gridSize']}x{lv['gridSize']} arrows={len(lv['arrows']):2d} "
            f"free={count_free(lv['arrows'], lv['gridSize'])} "
            f"chain={longest_lock_chain(lv['arrows'], lv['gridSize'])} {lv['difficulty']}",
            flush=True,
        )
    LEVELS.parent.mkdir(parents=True, exist_ok=True)
    LEVELS.write_text(json.dumps({"levels": levels}, indent=2))
    unsolved = [lv["id"] for lv in levels if solve(lv) is None]
    if unsolved:
        raise SystemExit(f"Unsolvable levels: {unsolved}")
    samples = [1, 10, 25, 50, 75, 100]
    print(f"Wrote {len(levels)} solvable levels")
    for i in samples:
        lv = levels[i - 1]
        free0 = count_free(lv["arrows"], lv["gridSize"])
        chain = longest_lock_chain(lv["arrows"], lv["gridSize"])
        avg_free, _ = playthrough_branching(lv)
        print(
            f"  L{i:3d}  {lv['gridSize']}x{lv['gridSize']}  arrows={len(lv['arrows']):2d}  "
            f"free={free0}  chain={chain}  avgFree={avg_free:.1f}  {lv['difficulty']}"
        )


if __name__ == "__main__":
    import sys

    if "--levels" in sys.argv:
        make_levels()
    else:
        make_assets()
        make_sounds()
        make_levels()
        print("Resources generated")
