# Batch Run Template

Use this compact payload for scene-level execution.

scene_dir=<absolute-or-relative-scene-dir>
prompt_schema=hi_kiki_scene_v1
score_threshold=89
image_size=1024x1024
image_target_kb=200
image_hard_limit_kb=none
image_minimize_policy=quality_first_best_effort
image_quality_guard=readability_first
source_image_immutable=true
derived_image_ext=png
derived_image_dir=<card_dir>
require_dual_regions=true
max_retry=2
step1_precheck_required=true
step1_precheck_mode=script_first
main_md_policy=card_md_only
prompt_md_write=false
cleanup_intermediate_files=true
shell_nullglob_safe=true
zsh_reserved_var_safe=true
long_command_split=true
html_preview_auto_reopen=true
non_contract_issue_policy=done_with_concerns

Expected behavior:
- Process only card subdirectories under scene_dir.
- Step 1 precheck first (script): check `1024x1024` and file readability.
- If precheck passes: reuse current derived image; if fails: regenerate derived image first.
- If user requests re-optimization, run Step 1 compression even when precheck passes.
- Step 1 first: read source image as immutable input, generate `<card>.normalized.png` in the same card directory (1024x1024, quality-first, minimize size as much as possible without visible quality loss).
- Step 2: run model parsing on derived image only (no fallback to source image).
- Step 2 output must include card text semantics + card/object coordinates; no template grid fallback.
- Step 2 gate: card/object pairing must pass same-target check; obvious mismatch is BLOCKED.
- Step 3: build JSON by fixed contract using MD semantics + image geometry.
- Main MD source is `<card>.md` only; never use `prompt.md` as lexical source.
- Do not generate or modify `prompt.md` during execution.
- After acceptance, remove intermediate artifacts such as `*.md-parse.tsv` and `*.md-json-compare.tsv`.
- Use zsh-safe null-glob patterns (for example `*.tsv(N)`) for cleanup commands.
- Never use `status` as a shell variable name in zsh; use `run_state`/`step_state`.
- Split long validation commands into short steps; avoid single mega-command chains.
- If preview page handle is invalid, reopen `hotspot-preview.html` and retry instead of blocking.
- Treat non-contract quality misses as `DONE_WITH_CONCERNS`, not `BLOCKED`.
- Retry only failed cards.
- Print compact summary only.
