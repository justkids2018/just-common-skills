# Batch Run Template

Use this compact payload for scene-level execution.

scene_dir=<absolute-or-relative-scene-dir>
score_threshold=89
image_size=1024x1024
image_max_kb=200
require_dual_regions=true
max_retry=2

Expected behavior:
- Process all card subdirectories under scene_dir.
- Enforce card+object by default.
- Retry only failed cards.
- Print compact summary only.
