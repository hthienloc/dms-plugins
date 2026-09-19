#!/usr/bin/env python3
"""Generate the bundled bongo-hit sounds for Bongo Cat.

The cat plays bongos, so the sounds are synthesized hand-drum hits. Each hit
is built from a physically-inspired model of a struck circular drumhead:

  * several inharmonic membrane modes (frequency ratios ~1.00, 1.59, 2.14,
    2.30, 2.65, 2.92 ... from the Bessel zeros of a circular membrane), with
    higher modes quieter and decaying faster — this is what makes it read as
    a real drum skin rather than a plain sine "tom";
  * a pitch glide (the head's pitch bends down as the strike energy decays);
  * a short broadband "slap" transient for the finger-on-skin attack.

Everything is generated from scratch, so it ships under the plugin's MIT
license with no third-party samples. Re-run to regenerate:

    python3 scripts/generate_sounds.py

Output: assets/sounds/{key.wav, key_alt.wav, space.wav, pop_key.wav, pop_key_alt.wav, pop_space.wav}
- key.wav         : higher bongo (macho)    — one paw
- key_alt.wav     : lower bongo  (hembra)   — the other paw
- space.wav       : deeper, louder hit      — big keys (space / enter)
- pop_key.wav     : bubble-pop (crisp, noise-based)  — one paw
- pop_key_alt.wav : bubble-pop (slightly softer)     — the other paw
- pop_space.wav   : bubble-pop (fuller air burst)    — big keys
"""

import wave
from pathlib import Path

import numpy as np

SR = 44100
OUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "sounds"

# Circular-membrane mode ratios with per-mode amplitude and a decay multiplier
# (smaller multiplier = faster decay). Higher modes are quieter and die sooner,
# which gives the bright attack that settles into a tonal ring.
MEMBRANE_MODES = [
    # (freq ratio, amplitude, decay multiplier)
    (1.00, 1.00, 1.00),
    (1.59, 0.55, 0.55),
    (2.14, 0.36, 0.42),
    (2.30, 0.28, 0.38),
    (2.65, 0.19, 0.30),
    (2.92, 0.13, 0.24),
    (3.16, 0.09, 0.20),
]


def bongo(duration_s, f0, bend, tau_bend, tau_decay, slap_level, seed, peak=0.85):
    """A struck-drumhead hit.

    f0          fundamental (open-tone) frequency in Hz
    bend        how far the pitch starts above f0 (head tension drop)
    tau_bend    how fast the pitch settles back to f0
    tau_decay   amplitude decay time constant of the fundamental
    slap_level  level of the attack noise transient
    """
    rng = np.random.default_rng(seed)
    n = int(SR * duration_s)
    t = np.arange(n) / SR

    # Pitch starts high and bends down to f0; integrate to get instantaneous phase.
    f_base = f0 * (1.0 + bend * np.exp(-t / tau_bend))
    phase = 2.0 * np.pi * np.cumsum(f_base) / SR

    body = np.zeros(n)
    for ratio, amp, dmul in MEMBRANE_MODES:
        body += amp * np.sin(ratio * phase) * np.exp(-t / (tau_decay * dmul))

    # Attack slap: a very short noise transient for the hand-on-skin contact.
    slap = rng.standard_normal(n) * np.exp(-t / 0.0022) * slap_level

    sig = body + slap

    # Fade the first/last samples so truncation doesn't pop.
    fi = max(1, int(SR * 0.0004))
    sig[:fi] *= np.linspace(0.0, 1.0, fi)
    fo = max(1, int(SR * 0.008))
    sig[-fo:] *= np.linspace(1.0, 0.0, fo)

    maxabs = float(np.max(np.abs(sig))) or 1.0
    return sig / maxabs * peak


def pop(duration_s, snap_decay, air_tau, air_level, seed, peak=0.85):
    """A bubble-pop sound — crisp, noise-based, no tonal ring.

    Models a small membrane (bubble wall) bursting: a sharp noise snap
    followed by a brief air hiss.  No sinusoidal content, so it reads as
    "pop" rather than "drum".

    snap_decay  how fast the rupture transient dies (seconds)
    air_tau     decay time of the escaping-air noise (seconds)
    air_level   level of the air component relative to the snap
    """
    rng = np.random.default_rng(seed)
    n = int(SR * duration_s)
    t = np.arange(n) / SR

    # Snap: ultra-short noise impulse — the membrane rupturing.
    snap = rng.standard_normal(n) * np.exp(-t / snap_decay)

    # Air burst: noise that fades a bit slower — the hiss of escaping air.
    air = rng.standard_normal(n) * np.exp(-t / air_tau) * air_level

    sig = snap + air

    fi = max(1, int(SR * 0.0002))
    sig[:fi] *= np.linspace(0.0, 1.0, fi)
    fo = max(1, int(SR * 0.002))
    sig[-fo:] *= np.linspace(1.0, 0.0, fo)

    maxabs = float(np.max(np.abs(sig))) or 1.0
    return sig / maxabs * peak


def write_wav(path, sig):
    data = (np.clip(sig, -1.0, 1.0) * 32767).astype("<i2")
    with wave.open(str(path), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    print(f"wrote {path}  ({path.stat().st_size} bytes)")


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    # Higher bongo (macho) — one paw.
    write_wav(OUT_DIR / "key.wav",
              bongo(0.18, f0=400, bend=0.50, tau_bend=0.012, tau_decay=0.085,
                    slap_level=0.30, seed=1))
    # Lower bongo (hembra) — the other paw.
    write_wav(OUT_DIR / "key_alt.wav",
              bongo(0.22, f0=260, bend=0.50, tau_bend=0.016, tau_decay=0.110,
                    slap_level=0.28, seed=2))
    # Deeper, louder hit for the big keys.
    write_wav(OUT_DIR / "space.wav",
              bongo(0.26, f0=185, bend=0.55, tau_bend=0.020, tau_decay=0.140,
                    slap_level=0.38, seed=3, peak=0.92))

    # Pop sounds — bubble-burst noise, no tonal ring.
    write_wav(OUT_DIR / "pop_key.wav",
              pop(0.030, snap_decay=0.0015, air_tau=0.007, air_level=0.55,
                  seed=4))
    write_wav(OUT_DIR / "pop_key_alt.wav",
              pop(0.035, snap_decay=0.0018, air_tau=0.008, air_level=0.50,
                  seed=5))
    write_wav(OUT_DIR / "pop_space.wav",
              pop(0.045, snap_decay=0.0020, air_tau=0.010, air_level=0.60,
                  seed=6, peak=0.92))


if __name__ == "__main__":
    main()
