#!/usr/bin/env python3
"""
Generate Chinese/English audio from card JSON text fields and upload to Qiniu /audio path.

Default source fields:
- Chinese text: item["text"]
- English text: item["text_english"]

Upload flow reuses server token endpoint:
GET {api_base}/api/v1/admin/upload/token
POST multipart to returned upload_url with token/key/file
"""

from __future__ import annotations

import argparse
import asyncio
import base64
import datetime as dt
import hashlib
import hmac
import json
import mimetypes
import os
import re
import shutil
import sys
import tempfile
from pathlib import Path
from typing import Any, Dict, List, Tuple

import requests


DEFAULT_ZH_VOICE = "zh-CN-XiaoyiNeural"
DEFAULT_EN_VOICE = "en-US-AnaNeural"


class WorkflowError(Exception):
    pass


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate TTS audio from card JSON and upload to Qiniu /audio"
    )
    parser.add_argument("json_path", help="Path to card JSON file")
    parser.add_argument(
        "--api-base",
        default=os.getenv("KIKI_API_BASE", "http://127.0.0.1:8080"),
        help="API base URL for token endpoint",
    )
    parser.add_argument(
        "--token-source",
        default=os.getenv("KIKI_TOKEN_SOURCE", "auto"),
        choices=["auto", "api", "direct"],
        help="How to get upload token: auto/api/direct",
    )
    parser.add_argument(
        "--auth-token",
        default=os.getenv("KIKI_ADMIN_TOKEN", ""),
        help="Optional bearer token for protected admin endpoint",
    )
    parser.add_argument(
        "--key-prefix",
        default="kiki/audio",
        help="Qiniu key prefix",
    )
    parser.add_argument(
        "--name-strategy",
        default="split",
        choices=["split", "concat", "id", "global_text"],
        help="Audio filename strategy: split (default), concat, id, or global_text",
    )
    parser.add_argument(
        "--upload-url-override",
        default=os.getenv("KIKI_QINIU_UPLOAD_URL", ""),
        help="Optional override for qiniu upload url",
    )
    parser.add_argument(
        "--domain-override",
        default=os.getenv("KIKI_QINIU_DOMAIN", ""),
        help="Optional override for qiniu domain (host or full URL)",
    )
    parser.add_argument(
        "--public-base-url",
        default=os.getenv("KIKI_QINIU_PUBLIC_BASE", "http://img.keepthinking.me"),
        help="Public base URL used in JSON writeback, e.g. http://img.keepthinking.me",
    )
    parser.add_argument(
        "--qiniu-access-key",
        default=os.getenv("QINIU_ACCESS_KEY", ""),
        help="Qiniu access key for direct token generation",
    )
    parser.add_argument(
        "--qiniu-secret-key",
        default=os.getenv("QINIU_SECRET_KEY", ""),
        help="Qiniu secret key for direct token generation",
    )
    parser.add_argument(
        "--qiniu-bucket",
        default=os.getenv("QINIU_BUCKET", ""),
        help="Qiniu bucket for direct token generation",
    )
    parser.add_argument(
        "--qiniu-domain",
        default=os.getenv("QINIU_DOMAIN", "img.keepthinking.me"),
        help="Qiniu public domain",
    )
    parser.add_argument(
        "--qiniu-upload-url",
        default=os.getenv("QINIU_UPLOAD_URL", "https://up-z2.qiniup.com"),
        help="Qiniu upload host for direct mode",
    )
    parser.add_argument(
        "--token-ttl-seconds",
        type=int,
        default=3600,
        help="TTL for direct generated token",
    )
    parser.add_argument(
        "--zh-voice",
        default=DEFAULT_ZH_VOICE,
        help="Edge TTS Chinese voice",
    )
    parser.add_argument(
        "--en-voice",
        default=DEFAULT_EN_VOICE,
        help="Edge TTS English voice",
    )
    parser.add_argument(
        "--zh-rate",
        default="+0%",
        help="Edge TTS rate for Chinese",
    )
    parser.add_argument(
        "--en-rate",
        default="+0%",
        help="Edge TTS rate for English",
    )
    parser.add_argument(
        "--writeback-json",
        action="store_true",
        help="Write uploaded audio URLs back into JSON",
    )
    parser.add_argument(
        "--output-json-path",
        default="",
        help="Optional output JSON path. If set with --writeback-json, writes to this file and keeps source unchanged.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Generate audio only, skip uploading",
    )
    parser.add_argument(
        "--write-manifest",
        action="store_true",
        help="Write <json>.audio-manifest.json (disabled by default)",
    )
    parser.add_argument(
        "--skip-verify-html",
        action="store_true",
        help="Do not write 一键音频验证.html next to output JSON",
    )
    return parser.parse_args()


def sanitize_segment(value: str) -> str:
    v = value.strip().lower()
    v = re.sub(r"[^a-z0-9_-]+", "-", v)
    v = re.sub(r"-+", "-", v).strip("-")
    if v:
        return v
    digest = hashlib.md5(value.encode("utf-8")).hexdigest()[:8]
    return f"seg-{digest}"


def sanitize_zh_segment(value: str) -> str:
    v = value.strip()
    v = re.sub(r"[^\u4e00-\u9fffA-Za-z0-9_-]+", "-", v)
    v = re.sub(r"-+", "-", v).strip("-")
    if v:
        return v
    digest = hashlib.md5(value.encode("utf-8")).hexdigest()[:8]
    return f"zh-{digest}"


def build_audio_stems(
    item_id: str,
    cn_text: str,
    en_text: str,
    strategy: str,
    zh_voice: str,
    en_voice: str,
    zh_rate: str,
    en_rate: str,
) -> Tuple[str, str]:
    zh_seg = sanitize_zh_segment(cn_text) if cn_text else ""
    en_seg = sanitize_segment(en_text) if en_text else ""

    if strategy == "id":
        return item_id, item_id

    if strategy == "global_text":
        cn_digest = hashlib.md5(f"cn|{cn_text}|{zh_voice}|{zh_rate}".encode("utf-8")).hexdigest()[:6]
        en_digest = hashlib.md5(f"en|{en_text}|{en_voice}|{en_rate}".encode("utf-8")).hexdigest()[:6]
        return f"{zh_seg or item_id}-{cn_digest}", f"{en_seg or item_id}-{en_digest}"

    # Prevent collisions when words repeat in the same JSON.
    seed = f"{item_id}|{cn_text}|{en_text}"
    short_hash = hashlib.md5(seed.encode("utf-8")).hexdigest()[:6]

    if strategy == "concat":
        if zh_seg and en_seg:
            base = f"{zh_seg}-{en_seg}"
        elif zh_seg:
            base = zh_seg
        elif en_seg:
            base = en_seg
        else:
            base = item_id
        stem = f"{base}-{short_hash}"
        return stem, stem

    # split (default): Chinese audio keeps Chinese word, English audio keeps English word.
    cn_base = zh_seg or item_id
    en_base = en_seg or item_id
    return f"{cn_base}-{short_hash}", f"{en_base}-{short_hash}"


def ensure_list_payload(payload: Any) -> List[Dict[str, Any]]:
    if not isinstance(payload, list):
        raise WorkflowError("JSON root must be a list")
    out: List[Dict[str, Any]] = []
    for i, item in enumerate(payload):
        if not isinstance(item, dict):
            raise WorkflowError(f"Item at index {i} is not an object")
        out.append(item)
    return out


def build_headers(auth_token: str) -> Dict[str, str]:
    headers: Dict[str, str] = {}
    if auth_token:
        headers["Authorization"] = f"Bearer {auth_token}"
    return headers


def parse_token_response(resp: Dict[str, Any]) -> Tuple[str, str, str]:
    data = resp.get("data") if isinstance(resp, dict) else None
    if not isinstance(data, dict):
        raise WorkflowError("Unexpected upload token response shape: missing data")

    token = data.get("token")
    upload_url = data.get("upload_url")
    domain = data.get("domain")

    if not token or not upload_url or not domain:
        raise WorkflowError("Upload token response missing token/upload_url/domain")

    return str(token), str(upload_url), str(domain)


def _urlsafe_b64(data: bytes) -> str:
    # Qiniu token signature validation is sensitive to exact base64 output.
    return base64.urlsafe_b64encode(data).decode("utf-8")


def build_direct_upload_token(access_key: str, secret_key: str, bucket: str, ttl_seconds: int) -> str:
    deadline = int(dt.datetime.now().timestamp()) + ttl_seconds
    put_policy = {
        "scope": bucket,
        "deadline": deadline,
        # Required by some buckets with strict MIME validation.
        "mimeLimit": "audio/*",
    }
    encoded_policy = _urlsafe_b64(json.dumps(put_policy, separators=(",", ":")).encode("utf-8"))
    sign = hmac.new(secret_key.encode("utf-8"), encoded_policy.encode("utf-8"), hashlib.sha1).digest()
    encoded_sign = _urlsafe_b64(sign)
    return f"{access_key}:{encoded_sign}:{encoded_policy}"


def get_upload_target(args: argparse.Namespace) -> Tuple[str, str, str]:
    # 1) direct mode
    if args.token_source == "direct":
        if not (args.qiniu_access_key and args.qiniu_secret_key and args.qiniu_bucket):
            raise WorkflowError(
                "Direct mode requires QINIU_ACCESS_KEY/QINIU_SECRET_KEY/QINIU_BUCKET"
            )
        token = build_direct_upload_token(
            args.qiniu_access_key,
            args.qiniu_secret_key,
            args.qiniu_bucket,
            args.token_ttl_seconds,
        )
        return token, args.qiniu_upload_url.strip(), args.qiniu_domain.strip()

    # 2) api mode
    if args.token_source == "api":
        return get_upload_token(args.api_base, args.auth_token)

    # 3) auto mode: try api first, fallback to direct
    try:
        return get_upload_token(args.api_base, args.auth_token)
    except Exception:
        if not (args.qiniu_access_key and args.qiniu_secret_key and args.qiniu_bucket):
            raise WorkflowError(
                "Auto mode failed to fetch API token and direct credentials are missing"
            )
        token = build_direct_upload_token(
            args.qiniu_access_key,
            args.qiniu_secret_key,
            args.qiniu_bucket,
            args.token_ttl_seconds,
        )
        return token, args.qiniu_upload_url.strip(), args.qiniu_domain.strip()


def get_upload_token(api_base: str, auth_token: str) -> Tuple[str, str, str]:
    url = api_base.rstrip("/") + "/api/v1/admin/upload/token"
    res = requests.get(url, headers=build_headers(auth_token), timeout=20)
    if res.status_code >= 400:
        raise WorkflowError(f"Failed to get upload token: HTTP {res.status_code} {res.text}")

    body = res.json()
    return parse_token_response(body)


def _is_qiniu_file_exists_error(status_code: int, body: str) -> bool:
    return status_code == 614 and "file exists" in body.lower()


def upload_file(upload_url: str, token: str, key: str, file_path: Path) -> str:
    mime = mimetypes.guess_type(file_path.name)[0] or "audio/mpeg"
    with file_path.open("rb") as f:
        files = {
            "file": (file_path.name, f, mime),
        }
        data = {
            "token": token,
            "key": key,
        }
        res = requests.post(upload_url, data=data, files=files, timeout=60)

    if res.status_code >= 400:
        if _is_qiniu_file_exists_error(res.status_code, res.text):
            return "exists"
        raise WorkflowError(f"Qiniu upload failed for {key}: HTTP {res.status_code} {res.text}")

    return "uploaded"


def build_public_url(domain: str, key: str, public_base_url: str) -> str:
    key_part = key.lstrip("/")
    base = public_base_url.strip()

    if base:
        base = base.rstrip("/")
        return f"{base}/{key_part}"

    d = domain.strip()
    if d.startswith("http://") or d.startswith("https://"):
        return f"{d.rstrip('/')}/{key_part}"

    return f"http://{d.strip('/')}/{key_part}"


async def synthesize_to_file(text: str, voice: str, rate: str, output_file: Path) -> None:
    try:
        import edge_tts  # type: ignore
    except ImportError as exc:
        raise WorkflowError(
            "Missing dependency edge-tts. Install with: pip install edge-tts"
        ) from exc

    communicate = edge_tts.Communicate(text=text, voice=voice, rate=rate)
    await communicate.save(str(output_file))


def extract_text_pair(item: Dict[str, Any]) -> Tuple[str, str]:
    cn = str(item.get("text") or "").strip()
    en = str(item.get("text_english") or "").strip()
    return cn, en


def get_item_id(item: Dict[str, Any], index: int) -> str:
    val = str(item.get("id") or "").strip()
    return val if val else f"item_{index + 1:03d}"


def update_item_audio_fields(
    item: Dict[str, Any],
    cn_key: str,
    en_key: str,
    cn_url: str,
    en_url: str,
) -> None:
    if cn_key:
        item["audio_cn_key"] = cn_key
    if cn_url:
        item["audio_cn_url"] = cn_url
    if en_key:
        item["audio_en_key"] = en_key
    if en_url:
        item["audio_en_url"] = en_url


def write_manifest(path: Path, manifest: Dict[str, Any]) -> None:
    path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")


def write_verify_html(output_json_path: Path, items: List[Dict[str, Any]]) -> Path:
    template_path = Path(__file__).resolve().parent.parent / "templates" / "audio-verify.html"
    if not template_path.exists():
        raise WorkflowError(f"Audio verify template not found: {template_path}")

    html = template_path.read_text(encoding="utf-8")
    json_path_literal = json.dumps(str(output_json_path.resolve()), ensure_ascii=False)
    embedded_json_literal = json.dumps(items, ensure_ascii=False, indent=2)
    html = html.replace('const DEFAULT_JSON_PATH = "";', f"const DEFAULT_JSON_PATH = {json_path_literal};")
    html = html.replace("const EMBEDDED_AUDIO_JSON = null;", f"const EMBEDDED_AUDIO_JSON = {embedded_json_literal};")

    verify_html_path = output_json_path.parent / "一键音频验证.html"
    verify_html_path.write_text(html, encoding="utf-8")
    return verify_html_path


def backup_file(path: Path) -> Path:
    ts = dt.datetime.now().strftime("%Y%m%d_%H%M%S")
    backup = path.with_suffix(path.suffix + f".bak.{ts}")
    shutil.copy2(path, backup)
    return backup


def resolve_output_json_path(source_json_path: Path, output_json_path: str) -> Path:
    raw = (output_json_path or "").strip()
    if not raw:
        return source_json_path

    out = Path(raw).expanduser()
    if out.is_absolute():
        return out.resolve()

    # For multi-level relative paths (e.g. kiki_web/doc/..../x_audio.json),
    # prefer resolving from current working directory when it clearly points to
    # a workspace-root path. This avoids accidental nested duplicate paths.
    cwd = Path.cwd()
    if out.parent != Path("."):
        cwd_candidate = (cwd / out).resolve()
        if (cwd / out.parts[0]).exists() or cwd_candidate.parent.exists():
            return cwd_candidate

    return (source_json_path.parent / out).resolve()


async def run() -> int:
    args = parse_args()
    json_path = Path(args.json_path).expanduser().resolve()
    if not json_path.exists():
        raise WorkflowError(f"JSON file not found: {json_path}")

    payload = json.loads(json_path.read_text(encoding="utf-8"))
    items = ensure_list_payload(payload)

    # Keep Chinese/English readability for scene-level folder segment.
    base_name = sanitize_zh_segment(json_path.stem)
    item_results: List[Dict[str, Any]] = []
    uploaded_count = 0
    exists_count = 0

    if args.dry_run:
        token = ""
        upload_url = ""
        domain = ""
    else:
        token, upload_url, domain = get_upload_target(args)

        if args.upload_url_override.strip():
            upload_url = args.upload_url_override.strip()
        if args.domain_override.strip():
            domain = args.domain_override.strip()

    with tempfile.TemporaryDirectory(prefix="kiki_tts_") as td:
        temp_dir = Path(td)

        for idx, item in enumerate(items):
            item_id = sanitize_segment(get_item_id(item, idx))
            cn_text, en_text = extract_text_pair(item)

            if not cn_text and not en_text:
                item_results.append(
                    {
                        "item_id": item_id,
                        "status": "skipped",
                        "reason": "empty_text",
                    }
                )
                continue

            cn_stem, en_stem = build_audio_stems(
                item_id,
                cn_text,
                en_text,
                args.name_strategy,
                args.zh_voice,
                args.en_voice,
                args.zh_rate,
                args.en_rate,
            )
            cn_file = temp_dir / f"{cn_stem}_cn.mp3"
            en_file = temp_dir / f"{en_stem}_en.mp3"

            if cn_text:
                await synthesize_to_file(cn_text, args.zh_voice, args.zh_rate, cn_file)
            if en_text:
                await synthesize_to_file(en_text, args.en_voice, args.en_rate, en_file)

            key_prefix = args.key_prefix.rstrip("/")
            if args.name_strategy == "global_text":
                cn_key = f"{key_prefix}/{cn_stem}_cn.mp3"
                en_key = f"{key_prefix}/{en_stem}_en.mp3"
            else:
                cn_key = f"{key_prefix}/{base_name}/{cn_stem}_cn.mp3"
                en_key = f"{key_prefix}/{base_name}/{en_stem}_en.mp3"

            cn_url = ""
            en_url = ""
            cn_upload_status = "skipped"
            en_upload_status = "skipped"

            if not args.dry_run:
                if cn_text:
                    cn_upload_status = upload_file(upload_url, token, cn_key, cn_file)
                    if cn_upload_status == "uploaded":
                        uploaded_count += 1
                    elif cn_upload_status == "exists":
                        exists_count += 1
                    cn_url = build_public_url(domain, cn_key, args.public_base_url)
                if en_text:
                    en_upload_status = upload_file(upload_url, token, en_key, en_file)
                    if en_upload_status == "uploaded":
                        uploaded_count += 1
                    elif en_upload_status == "exists":
                        exists_count += 1
                    en_url = build_public_url(domain, en_key, args.public_base_url)

            if args.writeback_json and not args.dry_run:
                update_item_audio_fields(item, cn_key, en_key, cn_url, en_url)

            item_results.append(
                {
                    "item_id": item_id,
                    "audio_stem_cn": cn_stem,
                    "audio_stem_en": en_stem,
                    "status": "ok",
                    "has_cn": bool(cn_text),
                    "has_en": bool(en_text),
                    "audio_cn_key": cn_key if cn_text else "",
                    "audio_en_key": en_key if en_text else "",
                    "audio_cn_url": cn_url,
                    "audio_en_url": en_url,
                    "upload_cn_status": cn_upload_status,
                    "upload_en_status": en_upload_status,
                }
            )

    backup_path = ""
    output_json_path = str(json_path)
    verify_html_path = ""
    if args.writeback_json and not args.dry_run:
        target_json_path = resolve_output_json_path(json_path, args.output_json_path)
        output_json_path = str(target_json_path)

        if target_json_path == json_path:
            backup = backup_file(json_path)
            backup_path = str(backup)
        else:
            target_json_path.parent.mkdir(parents=True, exist_ok=True)

        target_json_path.write_text(json.dumps(items, ensure_ascii=False, indent=2), encoding="utf-8")
        if not args.skip_verify_html:
            verify_html_path = str(write_verify_html(target_json_path, items))

    manifest_path = json_path.with_suffix(".audio-manifest.json")
    if args.write_manifest:
        manifest = {
            "json_path": str(json_path),
            "dry_run": args.dry_run,
            "writeback_json": args.writeback_json,
            "output_json_path": output_json_path,
            "backup_path": backup_path,
            "generated_at": dt.datetime.now().isoformat(),
            "results": item_results,
        }
        write_manifest(manifest_path, manifest)

    ok_count = sum(1 for x in item_results if x.get("status") == "ok")
    skip_count = sum(1 for x in item_results if x.get("status") == "skipped")

    print(
        f"DONE: ok={ok_count}, skipped={skip_count}, uploaded={uploaded_count}, exists={exists_count}"
    )
    if args.write_manifest:
        print(f"MANIFEST: {manifest_path}")
    if backup_path:
        print(f"BACKUP: {backup_path}")
    if verify_html_path:
        print(f"VERIFY_HTML: {verify_html_path}")

    return 0


def main() -> None:
    try:
        code = asyncio.run(run())
    except WorkflowError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(2)
    except KeyboardInterrupt:
        print("Interrupted", file=sys.stderr)
        sys.exit(130)
    else:
        sys.exit(code)


if __name__ == "__main__":
    main()
