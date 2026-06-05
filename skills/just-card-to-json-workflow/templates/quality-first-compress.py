#!/usr/bin/env python3
"""Quality-first image normalization and compression for card workflow.

Policy:
- Always output 1024x1024.
- Prioritize readability (text edges and object clarity).
- Minimize size as much as possible without visible degradation.
- No hard size cap.

Usage:
  python3 quality-first-compress.py /abs/path/card.png
  python3 quality-first-compress.py /abs/path/card.jpg --output /abs/path/card.normalized.png
  python3 quality-first-compress.py /abs/path/card.png --soft-target-kb 200
"""

from __future__ import annotations

import argparse
import io
import json
from pathlib import Path

from PIL import Image, ImageChops, ImageStat


SIZE = (1024, 1024)


def to_rgb_for_encoding(img: Image.Image) -> Image.Image:
    """Flatten alpha onto white to avoid transparency encoding surprises."""
    if img.mode in ("RGBA", "LA"):
        base = Image.new("RGB", img.size, (255, 255, 255))
        alpha = img.split()[-1]
        base.paste(img.convert("RGB"), mask=alpha)
        return base
    return img.convert("RGB")


def normalize_1024(img: Image.Image) -> Image.Image:
    if img.size == SIZE:
        return img
    return img.resize(SIZE, Image.Resampling.LANCZOS)


def png_bytes(img: Image.Image) -> bytes:
    buf = io.BytesIO()
    clean = img.copy()
    clean.info.pop("transparency", None)
    clean.save(buf, format="PNG", optimize=True, compress_level=9)
    return buf.getvalue()


def quality_ok(reference_rgb: Image.Image, candidate_rgb: Image.Image) -> tuple[bool, dict]:
    """Simple perceptual gate without external dependencies.

    Thresholds are tuned to keep labels and object edges visually reliable.
    """
    diff = ImageChops.difference(reference_rgb, candidate_rgb)
    stat = ImageStat.Stat(diff)

    mean_abs_err = sum(stat.mean) / len(stat.mean)
    max_channel_rms = max(stat.rms)

    ok = mean_abs_err <= 4.0 and max_channel_rms <= 10.0
    return ok, {
        "mae": round(mean_abs_err, 4),
        "max_rms": round(max_channel_rms, 4),
    }


def pick_best(
    reference_rgb: Image.Image,
    source_bytes_if_usable: bytes | None,
    soft_target_kb: float | None,
) -> tuple[bytes, str, dict]:
    best_bytes = png_bytes(reference_rgb)
    best_label = "lossless_optimize"
    _, best_quality = quality_ok(reference_rgb, reference_rgb)

    # Keep original bytes as baseline when source is already 1024x1024 PNG.
    if source_bytes_if_usable is not None and len(source_bytes_if_usable) < len(best_bytes):
        best_bytes = source_bytes_if_usable
        best_label = "reuse_source_png"

    best_size = len(best_bytes)

    def consider(candidate_for_save: Image.Image, candidate_rgb: Image.Image, label: str) -> None:
        nonlocal best_bytes, best_label, best_quality, best_size
        ok, q = quality_ok(reference_rgb, candidate_rgb)
        if not ok:
            return

        data = png_bytes(candidate_for_save)
        size = len(data)
        if size < best_size:
            best_bytes = data
            best_label = label
            best_quality = q
            best_size = size

    # 1) Palette quantization first, from conservative to aggressive.
    for colors in (256, 224, 192, 160, 128, 112, 96, 80, 64, 48, 32):
        p = reference_rgb.quantize(colors=colors, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
        consider(p, p.convert("RGB"), f"palette_{colors}")
        if soft_target_kb is not None and best_size <= soft_target_kb * 1024:
            break

    # 2) Light lossy bridge, then palette again.
    if soft_target_kb is None or best_size > soft_target_kb * 1024:
        for qv in (95, 92, 90, 88, 86, 84, 82, 80):
            jpeg_buf = io.BytesIO()
            reference_rgb.save(jpeg_buf, format="JPEG", quality=qv, optimize=True)
            jpeg_buf.seek(0)
            jpeg_img = Image.open(jpeg_buf).convert("RGB")

            consider(jpeg_img, jpeg_img, f"jpeg_{qv}")
            for colors in (224, 192, 160, 128, 112, 96, 80, 64, 48, 32):
                p = jpeg_img.quantize(colors=colors, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
                consider(p, p.convert("RGB"), f"jpeg_{qv}_palette_{colors}")
                if soft_target_kb is not None and best_size <= soft_target_kb * 1024:
                    break
            if soft_target_kb is not None and best_size <= soft_target_kb * 1024:
                break

    return best_bytes, best_label, best_quality


def main() -> None:
    parser = argparse.ArgumentParser(description="Quality-first normalize/compress for card images")
    parser.add_argument("source", help="Source image path (png/jpg/jpeg)")
    parser.add_argument("--output", help="Output path, default: <source_stem>.normalized.png")
    parser.add_argument(
        "--soft-target-kb",
        type=float,
        default=None,
        help="Optional soft target only (not a hard limit).",
    )
    args = parser.parse_args()

    src = Path(args.source).expanduser().resolve()
    if not src.exists():
        raise SystemExit(f"Source not found: {src}")

    out = (
        Path(args.output).expanduser().resolve()
        if args.output
        else src.with_name(f"{src.stem}.normalized.png")
    )

    before_size = src.stat().st_size
    with Image.open(src) as im:
        source_bytes_if_usable = None
        if im.size == SIZE and (im.format or "").upper() == "PNG":
            source_bytes_if_usable = src.read_bytes()
        norm = normalize_1024(im)
        ref = to_rgb_for_encoding(norm)

    best_data, strategy, quality = pick_best(ref, source_bytes_if_usable, args.soft_target_kb)

    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_bytes(best_data)
    after_size = out.stat().st_size

    reduction_ratio = 0.0
    if before_size > 0:
        reduction_ratio = (before_size - after_size) / before_size

    report = {
        "status": "PASSED" if after_size <= before_size else "DONE_WITH_CONCERNS",
        "source": str(src),
        "output": str(out),
        "pixel_width": SIZE[0],
        "pixel_height": SIZE[1],
        "file_size_before_kb": round(before_size / 1024, 2),
        "file_size_after_kb": round(after_size / 1024, 2),
        "reduction_ratio": round(reduction_ratio, 4),
        "strategy": strategy,
        "quality_metrics": quality,
        "soft_target_kb": args.soft_target_kb,
    }

    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
