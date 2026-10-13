#!/usr/bin/env python3
"""
l10n_lint — validate Localizable.strings / Localizable.stringsdict across all languages.

Catches the classes of defect that survive a Weblate round-trip and only surface at
runtime: lost format placeholders, stray '%' that printf reinterprets as a conversion,
MEGA's own '[A]' markup tokens corrupted or dropped by a translator, and plural
variants that resolve to nothing (rendering the literal string "(null)").

Severity maps to observed runtime behaviour, not to spec pedantry:

  error    the user sees something broken — "(null)", garbage memory, a lost placeholder
  warning  the user sees something wrong but intelligible — dropped '%' sign, bad grammar
  info     no user-visible effect today; worth cleaning up

Exit codes:
  0 = clean
  1 = blocking findings
  2 = tool failure, or a file that does not parse (unless --fail-on never)

Changes-only mode (--changed-since <rev>) lints the full files, then keeps only the
findings on keys that changed since the merge base of <rev> and HEAD. It also lints the
merge base, so a problem that already exists there is listed apart as "known".

Python 3 stdlib only. Reading .strings files needs macOS `plutil`.
"""

from __future__ import annotations

import argparse
import collections
import hashlib
import html
import io
import json
import os
import plistlib
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import xml.etree.ElementTree as ET

# --------------------------------------------------------------------------------------
# CLDR cardinal plural rules
# --------------------------------------------------------------------------------------
# Only the integer (v=0, f=0) branch of each rule is modelled: every count the app feeds
# into a stringsdict is an Int. That restriction matters — under it, `other` is
# *unreachable* in pl and ru, which is why those languages ship 200+ entries with no
# `other` variant and still render correctly.

PLURAL_CATEGORIES = ("zero", "one", "two", "few", "many", "other")


def _cat_other(_n: int) -> str:
    return "other"


def _cat_one_is_1(n: int) -> str:
    return "one" if n == 1 else "other"


def _cat_one_is_0_or_1(n: int) -> str:
    return "one" if n in (0, 1) else "other"


def _million(n: int) -> bool:
    return n != 0 and n % 1_000_000 == 0


def _cat_ar(n: int) -> str:
    if n == 0:
        return "zero"
    if n == 1:
        return "one"
    if n == 2:
        return "two"
    r = n % 100
    if 3 <= r <= 10:
        return "few"
    if 11 <= r <= 99:
        return "many"
    return "other"


def _cat_es(n: int) -> str:
    if n == 1:
        return "one"
    return "many" if _million(n) else "other"


def _cat_fr(n: int) -> str:
    if n in (0, 1):
        return "one"
    return "many" if _million(n) else "other"


def _cat_it(n: int) -> str:
    if n == 1:
        return "one"
    return "many" if _million(n) else "other"


def _cat_pt(n: int) -> str:
    if n in (0, 1):
        return "one"
    return "many" if _million(n) else "other"


def _cat_pl(n: int) -> str:
    if n == 1:
        return "one"
    r10, r100 = n % 10, n % 100
    if 2 <= r10 <= 4 and not (12 <= r100 <= 14):
        return "few"
    return "many"  # `other` is unreachable for integers in pl


def _cat_ru(n: int) -> str:
    r10, r100 = n % 10, n % 100
    if r10 == 1 and r100 != 11:
        return "one"
    if 2 <= r10 <= 4 and not (12 <= r100 <= 14):
        return "few"
    return "many"  # `other` is unreachable for integers in ru


def _cat_ro(n: int) -> str:
    if n == 1:
        return "one"
    if n == 0 or 1 <= (n % 100) <= 19:
        return "few"
    return "other"


PLURAL_RULE = {
    "ar": _cat_ar,
    "de": _cat_one_is_1,
    "en": _cat_one_is_1,
    "es": _cat_es,
    "fr": _cat_fr,
    "id": _cat_other,
    "it": _cat_it,
    "ja": _cat_other,
    "ko": _cat_other,
    "nl": _cat_one_is_1,
    "pl": _cat_pl,
    "pt": _cat_pt,
    "ro": _cat_ro,
    "ru": _cat_ru,
    "th": _cat_other,
    "tr": _cat_one_is_1,
    "vi": _cat_other,
    "zh-Hans": _cat_other,
    "zh-Hant": _cat_other,
}

# Counts the app plausibly renders. Split so that a category only reachable at 10^6
# (es/fr/it/pt `many`) is reported as cosmetic rather than blocking.
COMMON_COUNTS = tuple(range(0, 201))
LARGE_COUNTS = (1_000, 10_000, 100_000, 1_000_000, 1_000_001, 2_000_000)


def plural_category(lang: str, n: int) -> str:
    return PLURAL_RULE.get(lang, _cat_one_is_1)(n)


# --------------------------------------------------------------------------------------
# printf format-string model
# --------------------------------------------------------------------------------------
# SwiftGen's generated tr() calls String(format:locale:arguments:) unconditionally — even
# for keys that take no arguments. So *every* stray '%' in *any* translation is fed to
# printf, and a '%' that happens to precede a conversion character silently consumes an
# argument slot that was never supplied.
#
# Legacy keys (a key with a space or a '%', see key_leaf) are an exception. The app reads
# them with a raw bundle lookup and replaces '%1', '%2' itself, so their bare '%1' is a
# placeholder, not printf input.

CONVERSIONS = "@dDiuUxXoOfFeEgGcCsSpaA"
INTEGER_CONVERSIONS = "dDiuUxXoOcC"
# On arm64 these length modifiers make an integer conversion read 64 bits.
WIDE_LENGTHS = ("l", "ll", "q", "z", "j", "t")

_TOKEN = re.compile(
    r"%%"                                     # escaped literal percent
    r"|%(?:(\d+)\$)?"                         # 1: optional positional index
    r"([-+ #0]*)"                             # 2: flags (note: space is a flag)
    r"(\d+|\*)?"                              # 3: width
    r"([-+ #0]*)"                             # 4: Foundation also reads flags after the width
    r"(?:\.(\d+|\*))?"                        # 5: precision
    r"(hh|h|ll|l|q|L|z|j|t)?"                 # 6: length modifier
    r"([" + CONVERSIONS + r"])"               # 7: conversion
    r"|%"                                     # a bare '%' matching none of the above
)

FormatSig = collections.namedtuple("FormatSig", "slots bare positional wide space_flag")


def format_signature(s: str) -> FormatSig:
    """Model how Foundation's printf will read `s`.

    slots       {argument index -> conversion char}, 1-based, in printf's own numbering.
                A '*' width or precision takes its own int slot, shown as '*'.
    bare        count of '%' that form no conversion (printf drops or passes them through)
    positional  True if the string uses explicit %n$ indices
    wide        argument indices read with a 64-bit length modifier (%ld, %lld, %zu ...)
    space_flag  conversions that carry a space flag, e.g. '% c' in '16% cheaper'
    """
    slots: dict = {}
    wide: set = set()
    space_flag: list = []
    bare = 0
    seq = 0
    positional = False
    for m in _TOKEN.finditer(s):
        token = m.group(0)
        if token == "%%":
            continue
        if m.group(7) is None:
            bare += 1
            continue
        if m.group(1):
            positional = True
            idx = int(m.group(1))
        else:
            for star in (m.group(3), m.group(5)):
                if star == "*":
                    seq += 1
                    slots[seq] = "*"
            seq += 1
            idx = seq
        slots[idx] = m.group(7)
        if m.group(6) in WIDE_LENGTHS and m.group(7) in INTEGER_CONVERSIONS:
            wide.add(idx)
        if " " in m.group(2) + m.group(4):
            space_flag.append(token)
    return FormatSig(slots, bare, positional, wide, space_flag)


def _describe(sig: FormatSig) -> str:
    if not sig.slots:
        return "no arguments"
    return ", ".join(f"%{i}=%{c}" for i, c in sorted(sig.slots.items()))


# '%1' followed by text, as in '%1 of %2'. '%10d' and '%1$@' are real conversions.
_LEGACY_PLACEHOLDER = re.compile(r"%(\d+)(?![\d$]|\.\d|[hlqLzjt" + CONVERSIONS + r"])")


def strip_legacy_placeholders(s: str):
    """Remove '%1'-style placeholders. Returns (rest, Counter of placeholder numbers)."""
    found = collections.Counter(_LEGACY_PLACEHOLDER.findall(s))
    return _LEGACY_PLACEHOLDER.sub("", s), found


# --------------------------------------------------------------------------------------
# MEGA bracket markup tokens
# --------------------------------------------------------------------------------------
# Separate from printf: '[A]' / '[/A]' / '[B]' are MEGA's own tokens, substituted in Swift
# by replacingOccurrences(of:) or sliced out by subString(from:to:) — always *after*
# String(format:) has already run over the value. So printf sees them as literal text, and
# anything that perturbs them survives all the way to the call site as a plain
# string-match failure with no error raised.

# ASCII only: '[entschlüsselt]' in a translation is prose, not a token.
_BRACKET_TOKEN = re.compile(r"\[/?[A-Za-z][A-Za-z0-9_]*\]")
_GLUE_GAP = re.compile(r"[-+ #0]*")


def bracket_tokens(s: str) -> collections.Counter:
    """Multiset of MEGA markup tokens in `s`."""
    return collections.Counter(_BRACKET_TOKEN.findall(s))


def percent_glued_tokens(s: str):
    """Tokens with a bare '%' in front, e.g. '%[A]' or '% [A]'.

    printf has no '[' conversion, so '%[' is an invalid specifier. Foundation on macOS
    drops the '%' and keeps the token ('a %[A]b' -> 'a [A]b'). With other text around
    it, it can also cut off the rest of the string ('pre % [A]x' -> 'pre ').

    '%%[A]' is correct (an escaped literal percent followed by an intact token) and is
    not reported — the shared tokenizer consumes '%%' before this ever looks at it.
    """
    hits = []
    for m in _TOKEN.finditer(s):
        if m.group(0) == "%%" or m.group(7) is not None:
            continue  # escaped percent, or a well-formed conversion
        gap_end = _GLUE_GAP.match(s, m.end()).end()
        token = _BRACKET_TOKEN.match(s, gap_end)
        if token:
            hits.append(token.group(0))
    return hits


# --------------------------------------------------------------------------------------
# Findings
# --------------------------------------------------------------------------------------

SEVERITIES = ("error", "warning", "info")


class Finding:
    __slots__ = ("severity", "rule", "lang", "key", "message", "detail", "path", "line",
                 "short", "value", "base_value", "fingerprint")

    def __init__(self, severity, rule, lang, key, message, detail="", path="", line=0,
                 short="", value=None, base_value=None):
        self.severity = severity
        self.rule = rule
        self.lang = lang
        self.key = key
        self.message = message
        self.detail = detail
        self.path = path
        self.line = line
        self.short = short or message
        self.value = value
        self.base_value = base_value
        # The message names the problem (slots, variant, token), so a new problem on a
        # known key gets a new fingerprint. Computed once: --check-unused edits message.
        raw = f"{rule}|{path}|{lang}|{key}|{message}"
        self.fingerprint = hashlib.sha1(raw.encode("utf-8")).hexdigest()[:16]

    def to_dict(self) -> dict:
        return {
            "fingerprint": self.fingerprint,
            "severity": self.severity,
            "rule": self.rule,
            "lang": self.lang,
            "key": self.key,
            "message": self.message,
            "detail": self.detail,
            "path": self.path,
            "line": self.line,
        }

    def __repr__(self) -> str:  # pragma: no cover - debugging aid
        return f"<{self.severity} {self.rule} {self.lang} {self.key}>"


# --------------------------------------------------------------------------------------
# Resource loading
# --------------------------------------------------------------------------------------


def parse_strings(path: str):
    """Parse a .strings file (UTF-8 or UTF-16, old-style plist) into a dict."""
    proc = subprocess.run(
        ["plutil", "-convert", "xml1", "-o", "-", path],
        capture_output=True,
    )
    if proc.returncode != 0:
        return None, proc.stderr.decode("utf-8", "replace").strip()
    try:
        return plistlib.loads(proc.stdout), None
    except Exception as exc:  # pragma: no cover - plutil output is already validated
        return None, str(exc)


def parse_stringsdict(path: str):
    try:
        with open(path, "rb") as handle:
            return plistlib.load(handle), None
    except FileNotFoundError:
        return {}, None
    except Exception as exc:
        return None, str(exc)


def read_text(path: str) -> str:
    with open(path, "rb") as handle:
        data = handle.read()
    if data[:2] in (b"\xff\xfe", b"\xfe\xff"):
        return data.decode("utf-16", "replace")
    return data.decode("utf-8", "replace")


_QUOTED = re.compile(r'"((?:[^"\\]|\\.)*)"', re.S)
_UNQUOTED = re.compile(r"[A-Za-z0-9_$+/:.\-]+")
_ESCAPE = re.compile(r"\\(U[0-9a-fA-F]{4}|u[0-9a-fA-F]{4}|.)", re.S)
_ESCAPES = {"n": "\n", "t": "\t", "r": "\r", "a": "\a", "b": "\b", "f": "\f", "v": "\v"}


def _unescape(s: str) -> str:
    def repl(m):
        code = m.group(1)
        if len(code) == 5:
            return chr(int(code[1:], 16))
        return _ESCAPES.get(code, code)
    return _ESCAPE.sub(repl, s)


def scan_strings_keys(text: str):
    """List (key, line) for each 'key = value;' pair in a .strings file, in file order.

    Comments are skipped and a leading BOM is ignored, like plutil does. The scan stops
    at the first syntax error; plutil reports that error separately.
    """
    pairs = []
    pos = 1 if text.startswith("﻿") else 0
    line, line_pos = 1, 0
    state, key, key_line = 0, None, 0  # 0: key, 1: '=' or ';', 2: value, 3: ';'
    while pos < len(text):
        ch = text[pos]
        if ch.isspace():
            pos += 1
            continue
        if text.startswith("//", pos):
            end = text.find("\n", pos)
            pos = len(text) if end < 0 else end
            continue
        if text.startswith("/*", pos):
            end = text.find("*/", pos + 2)
            pos = len(text) if end < 0 else end + 2
            continue
        line += text.count("\n", line_pos, pos)
        line_pos = pos
        if state in (0, 2):
            m = _QUOTED.match(text, pos) if ch == '"' else _UNQUOTED.match(text, pos)
            if not m:
                break
            if state == 0:
                key = _unescape(m.group(1)) if ch == '"' else m.group(0)
                key_line = line
            state += 1
            pos = m.end()
        elif state == 1 and ch == "=":
            state, pos = 2, pos + 1
        elif state in (1, 3) and ch == ";":
            pairs.append((key, key_line))
            state, pos = 0, pos + 1
        else:
            break
    return pairs


def raw_key_order(text: str):
    return [key for key, _ in scan_strings_keys(text)]


_PLIST_TAG = re.compile(r"<dict>|</dict>|<dict\s*/>|<key>(.*?)</key>", re.S)


def stringsdict_key_lines(text: str) -> dict:
    """{top-level key -> line number} for a .stringsdict file."""
    lines = {}
    depth = 0
    line, line_pos = 1, 0
    for m in _PLIST_TAG.finditer(text):
        tag = m.group(0)
        if tag == "<dict>":
            depth += 1
        elif tag == "</dict>":
            depth -= 1
        elif m.group(1) is not None and depth == 1:
            line += text.count("\n", line_pos, m.start())
            line_pos = m.start()
            lines.setdefault(html.unescape(m.group(1)), line)
    return lines


# --------------------------------------------------------------------------------------
# Dead-key detection (optional, advisory only)
# --------------------------------------------------------------------------------------

_IDENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
SOURCE_EXTS = (".swift", ".m", ".mm", ".h")


def collect_source_identifiers(roots) -> set:
    idents: set = set()
    for root in roots:
        for dirpath, dirnames, filenames in os.walk(root):
            dirnames[:] = [
                d for d in dirnames
                if d not in {".git", "derivedData", "build", ".build", "Pods"}
                and not d.endswith(".xcframework")
            ]
            for name in filenames:
                if not name.endswith(SOURCE_EXTS) or name.endswith("+Generated.swift"):
                    continue
                try:
                    text = read_text(os.path.join(dirpath, name))
                except OSError:
                    continue
                idents.update(_IDENT.findall(text))
    return idents


def key_leaf(key: str):
    """SwiftGen maps `a.b.cDee` -> `A.B.cDee`; the leaf is what appears at a call site."""
    leaf = key.rsplit(".", 1)[-1]
    if not leaf or not _IDENT.fullmatch(leaf):
        return None  # legacy keys with spaces/format specifiers — can't reason about them
    return leaf[0].lower() + leaf[1:]


def is_legacy_key(key: str) -> bool:
    return key_leaf(key) is None


# --------------------------------------------------------------------------------------
# Checks
# --------------------------------------------------------------------------------------

# en.lproj is a copy of Base.lproj. English devices load en, so it must not drift.
SOURCE_COPY_LANG = "en"
_PLURAL_REF = re.compile(r"%(?:\d+\$)?#@([^@]+)@")


def _plural_strings(entry):
    """Every string in a stringsdict entry: the format key and each variant category."""
    out = []
    for name, val in entry.items():
        if name == "NSStringLocalizedFormatKey" and isinstance(val, str):
            out.append(val)
        elif isinstance(val, dict):
            out.extend(str(val[c]) for c in PLURAL_CATEGORIES if c in val)
    return out


def _join_tokens(tokens) -> str:
    return ", ".join(f"`{t}`" for t in sorted(tokens))


class Linter:
    def __init__(self, root: str, base: str = "Base", counts=None, large_counts=None,
                 label=None):
        self.root = root
        # Paths in findings start with `label`. Two runs on different copies of the
        # same tree use the same label, so their fingerprints match.
        self.label = label or root
        self.base = base
        self.counts = COMMON_COUNTS if counts is None else tuple(counts)
        self.large_counts = LARGE_COUNTS if large_counts is None else tuple(large_counts)
        self.findings: list = []
        self.base_suspect_keys: set = set()
        self.base_token_set: set = set()
        self._line_cache: dict = {}

    # -- helpers ------------------------------------------------------------------
    def add(self, severity, rule, lang, key, message, detail="", path="", short="",
            value=None, base_value=None):
        shown = os.path.join(self.label, os.path.relpath(path, self.root)) if path else ""
        line = self._line(path, key) if path else 0
        self.findings.append(Finding(severity, rule, lang, key, message, detail, shown,
                                     line, short, value, base_value))

    def _line(self, path, key):
        if path not in self._line_cache:
            try:
                text = read_text(path)
            except OSError:
                text = ""
            if path.endswith(".stringsdict"):
                self._line_cache[path] = stringsdict_key_lines(text)
            else:
                self._line_cache[path] = dict(scan_strings_keys(text))
        return self._line_cache[path].get(key, 0)

    def languages(self):
        return sorted(
            d[: -len(".lproj")]
            for d in os.listdir(self.root)
            if d.endswith(".lproj") and os.path.isdir(os.path.join(self.root, d))
        )

    def lang_for_rules(self, lang: str) -> str:
        return "en" if lang == self.base else lang

    def _path(self, lang, filename):
        return os.path.join(self.root, f"{lang}.lproj", filename)

    # -- entry point --------------------------------------------------------------
    def run(self):
        spath = self._path(self.base, "Localizable.strings")
        base_strings, err = parse_strings(spath)
        if err:
            self.add("error", "parse-error", self.base, "Localizable.strings",
                     "base .strings does not parse", err, spath,
                     short="The file does not parse.")
            return self.findings
        dpath = self._path(self.base, "Localizable.stringsdict")
        base_dict, err = parse_stringsdict(dpath)
        if err:
            self.add("error", "parse-error", self.base, "Localizable.stringsdict",
                     "base .stringsdict does not parse", err, dpath,
                     short="The file does not parse.")
            return self.findings

        for key, value in base_strings.items():
            if not isinstance(value, str):
                continue
            self.base_token_set.update(bracket_tokens(value))
            if not is_legacy_key(key) and format_signature(value).space_flag:
                self.base_suspect_keys.add(key)
        for entry in base_dict.values():
            if isinstance(entry, dict):
                for text in _plural_strings(entry):
                    self.base_token_set.update(bracket_tokens(text))

        for lang in self.languages():
            self.check_language(lang, base_strings, base_dict)
        return self.findings

    # -- per language -------------------------------------------------------------
    def check_language(self, lang, base_strings, base_dict):
        is_base = lang == self.base
        spath = self._path(lang, "Localizable.strings")
        dpath = self._path(lang, "Localizable.stringsdict")

        strings, err = parse_strings(spath)
        if err:
            self.add("error", "parse-error", lang, "Localizable.strings",
                     ".strings does not parse", err, spath, short="The file does not parse.")
        else:
            self.check_duplicates(lang, spath)
            if not is_base:
                self.check_key_sets(lang, strings, base_strings, "missing-key",
                                    "orphan-key", spath)
            self.check_values(lang, strings, base_strings, is_base, spath)

        sdict, err = parse_stringsdict(dpath)
        if err:
            self.add("error", "parse-error", lang, "Localizable.stringsdict",
                     ".stringsdict does not parse", err, dpath,
                     short="The file does not parse.")
        else:
            if not is_base:
                self.check_key_sets(lang, sdict, base_dict, "missing-plural-key",
                                    "orphan-plural-key", dpath)
            self.check_plurals(lang, sdict, None if is_base else base_dict, dpath)

        if strings and sdict:
            for key in set(strings) & set(sdict):
                self.add("info", "key-in-both-tables", lang, key,
                         ".stringsdict entry shadows the .strings entry for this key",
                         path=dpath)

    def check_duplicates(self, lang, path):
        try:
            text = read_text(path)
        except OSError:
            return
        counts = collections.Counter(raw_key_order(text))
        for key, count in sorted(counts.items()):
            if count > 1:
                self.add("warning", "duplicate-key", lang, key,
                         f"declared {count} times in .strings — the last one wins",
                         path=path, short=f"Declared {count} times. The last one wins.")

    def check_key_sets(self, lang, table, base_table, missing_rule, orphan_rule, path):
        for key in sorted(set(base_table) - set(table)):
            self.add("warning", missing_rule, lang, key,
                     "present in Base but not in this language — renders English",
                     path=path, short="Missing. The app shows the English text.")
        for key in sorted(set(table) - set(base_table)):
            self.add("info", orphan_rule, lang, key,
                     "translated but absent from Base — stale, safe to prune",
                     path=path, short="Not in Base. Safe to remove.")

    def check_values(self, lang, strings, base_strings, is_base, path):
        for key in sorted(strings):
            value = strings[key]
            if not isinstance(value, str):
                self.add("error", "malformed-value", lang, key,
                         f"expected a string, found {type(value).__name__}", path=path)
                continue
            if not value.strip():
                self.add("error", "empty-value", lang, key,
                         "translation is empty — renders as blank", path=path,
                         short="Empty value.", value=value)
                continue
            # A welded '%' is self-evidently wrong from the value alone, so this runs on
            # Base too — the typo is just as damaging when a developer introduces it.
            self.check_glued_percent(lang, key, value, path)
            if is_base:
                self.check_base_value(lang, key, value, path)
                continue
            base_value = base_strings.get(key)
            if not isinstance(base_value, str):
                continue
            if lang == SOURCE_COPY_LANG and value != base_value:
                self.add("warning", "en-differs-from-base", lang, key,
                         "en.lproj must be a copy of Base.lproj, but this value differs",
                         path=path, short="en differs from Base.", value=value,
                         base_value=base_value)
            self.compare_tokens(lang, key, base_value, value, path)
            self.compare_formats(lang, key, base_value, value, path)
            self.compare_edge_newlines(lang, key, base_value, value, path)

    def check_base_value(self, lang, key, value, path):
        """Base is the source. A printf hazard here breaks every language at once."""
        text = strip_legacy_placeholders(value)[0] if is_legacy_key(key) else value
        sig = format_signature(text)
        if sig.space_flag and not is_legacy_key(key):
            spans = ", ".join(f"`{t}`" for t in sig.space_flag)
            self.add("error", "base-accidental-conversion", lang, key,
                     f"{spans} is read as a printf conversion with a space flag. It "
                     f"consumes an argument and the text after '%' is lost. Write '%%'. "
                     f"Translations of this key are not compared until this is fixed.",
                     f"{lang}: {value!r}", path,
                     short=f"{spans} is read as a printf conversion. Write `%%`.",
                     value=value)
        bare = sig.bare - len(percent_glued_tokens(text))
        if bare > 0 and not is_legacy_key(key):
            self.add("warning", "unescaped-percent", lang, key,
                     f"has {bare} unescaped '%'. printf drops it, so the '%' sign "
                     f"disappears. Write '%%'.",
                     f"{lang}: {value!r}", path, short="Unescaped `%`. Write `%%`.",
                     value=value)

    def check_glued_percent(self, lang, key, value, path, where=""):
        glued = percent_glued_tokens(value)
        if not glued:
            return
        label = f"{where}: " if where else ""
        names = _join_tokens(set(glued))
        self.add("warning", "percent-glued-to-token", lang, key,
                 f"{label}'%' is right before markup token(s) {names}. '%[' is not a "
                 f"printf conversion: Foundation drops the '%', and it can cut off the "
                 f"rest of the text. Write '%%'.",
                 f"{lang}: {value!r}", path,
                 short=f"{label}`%` right before {names}. The `%` is lost and the text "
                       f"can be cut off. Write `%%`.",
                 value=value)

    def compare_tokens(self, lang, key, base_value, value, path, where=""):
        base_tokens = bracket_tokens(base_value)
        tokens = bracket_tokens(value)
        label = f"{where}: " if where else ""
        plural = f"Plural `{where.split('.')[-1]}` " if where else ""
        evidence = f"base: {base_value!r}\n{lang}:  {value!r}"
        missing = base_tokens - tokens
        if missing:
            names = ", ".join(f"{t}×{n}" if n > 1 else t for t, n in sorted(missing.items()))
            short = f"{plural}{'drops' if plural else 'Drops'} {_join_tokens(missing)}."
            broken = [t for t in missing if t[1:] in value]
            if broken:
                short += f" The text has `{broken[0][1:]}`."
            self.add("error", "missing-markup-token", lang, key,
                     f"{label}drops markup token(s) {names} that Base declares — the Swift "
                     f"side string-matches on these, so the substitution or link range is "
                     f"lost silently",
                     evidence, path, short=short, value=value, base_value=base_value)
        # Surplus brackets are usually prose in the target language. Only a token that
        # no Base text uses is reported: no Swift code replaces it, so it shows as is.
        unknown = {t for t in tokens - base_tokens if t not in self.base_token_set}
        if unknown:
            self.add("warning", "unknown-markup-token", lang, key,
                     f"{label}has markup token(s) {_join_tokens(unknown)} that no Base "
                     f"text uses. No code replaces them, so they show as plain text.",
                     evidence, path,
                     short=f"{label}Has {_join_tokens(unknown)}, which no Base text uses.",
                     value=value, base_value=base_value)

    def compare_formats(self, lang, key, base_value, value, path, where="",
                        allow_missing=False, base_sig=None):
        if key in self.base_suspect_keys:
            return  # reported once on Base by check_base_value
        label = f"{where}: " if where else ""
        evidence = f"base: {base_value!r}\n{lang}:  {value!r}"
        base_text, text = base_value, value
        if is_legacy_key(key):
            base_text, base_raw = strip_legacy_placeholders(base_value)
            text, raw = strip_legacy_placeholders(value)
            lost = sorted(base_raw - raw, key=int)
            if lost:
                names = ", ".join(f"%{n}" for n in lost)
                self.add("error", "format-arity", lang, key,
                         f"{label}drops placeholder(s) {names} that the app replaces",
                         evidence, path, short=f"{label}Drops placeholder `{names}`.",
                         value=value, base_value=base_value)
        if base_sig is None:
            base_sig = format_signature(base_text)
        sig = format_signature(text)

        extra = sorted(set(sig.slots) - set(base_sig.slots))
        missing = [] if allow_missing else sorted(set(base_sig.slots) - set(sig.slots))
        if extra or missing:
            if extra and not missing:
                why = (f"consumes {len(extra)} argument slot(s) the caller never passes "
                       f"— printf reads past the end of the argument list")
                short = (f"Uses {len(extra)} more argument(s) than Base. The app reads "
                         f"garbage memory or crashes.")
            elif missing and not extra:
                why = f"drops placeholder(s) {missing} — that text is lost at runtime"
                short = "Drops placeholder " + ", ".join(f"`%{i}`" for i in missing) + "."
            else:
                why = f"argument slots differ (extra {extra}, missing {missing})"
                short = "Placeholders differ from Base."
            self.add("error", "format-arity", lang, key,
                     f"{label}{why}; base has {_describe(base_sig)}, translation has "
                     f"{_describe(sig)}",
                     evidence, path, short=label + short, value=value,
                     base_value=base_value)
            return

        for idx, got in sorted(sig.slots.items()):
            conv = base_sig.slots.get(idx)
            if conv is None:
                continue
            if got != conv:
                if conv == "@" and got in "sS":
                    message = (f"slot %{idx} is %s (C string) but the caller passes an "
                               f"object (%{conv}) — reads a bad pointer")
                    short = f"`%{got}` where Base has `%{conv}`. The app reads a bad pointer."
                else:
                    message = f"slot %{idx} is %{got} but base declares %{conv}"
                    short = f"`%{got}` where Base has `%{conv}`."
            elif idx in base_sig.wide and idx not in sig.wide:
                message = (f"slot %{idx} drops the 64-bit length modifier that Base has, "
                           f"so large numbers are cut to 32 bits")
                short = f"`%{got}` where Base has a 64-bit `%l{conv}`. Large numbers come out wrong."
            else:
                continue
            self.add("error", "format-type", lang, key, label + message, evidence, path,
                     short=label + short, value=value, base_value=base_value)

        # A '%' glued to a markup token is already reported by check_glued_percent;
        # discount it here so it isn't also counted as a plain dropped-'%'-sign warning.
        bare = sig.bare - len(percent_glued_tokens(text))
        base_bare = base_sig.bare - len(percent_glued_tokens(base_text))
        if bare > base_bare:
            self.add("warning", "unescaped-percent", lang, key,
                     f"{label}has {bare} unescaped '%' (base has {base_bare}) — printf "
                     f"swallows it, so the '%' sign disappears; write '%%'",
                     evidence, path, short=f"{label}Unescaped `%`. Write `%%`.",
                     value=value, base_value=base_value)

    def compare_edge_newlines(self, lang, key, base_value, value, path):
        for edge, test in (("starts", str.startswith), ("ends", str.endswith)):
            if test(value, "\n") != test(base_value, "\n"):
                where = "this language but not in Base" if test(value, "\n") else \
                    "Base but not in this language"
                self.add("warning", "newline-differs", lang, key,
                         f"{edge} with a line break in {where}. The text shows an extra "
                         f"or a missing blank line.",
                         f"base: {base_value!r}\n{lang}:  {value!r}", path,
                         short=f"Line break where the text {edge} differs from Base.",
                         value=value, base_value=base_value)

    # -- plurals ------------------------------------------------------------------
    def check_plurals(self, lang, sdict, base_dict, path):
        """base_dict is None for Base itself."""
        rules_lang = self.lang_for_rules(lang)
        for key in sorted(sdict):
            entry = sdict[key]
            if not isinstance(entry, dict):
                self.add("error", "plural-malformed", lang, key,
                         "entry is not a dictionary", path=path)
                continue
            fmt = entry.get("NSStringLocalizedFormatKey")
            if not isinstance(fmt, str):
                self.add("error", "plural-malformed", lang, key,
                         "missing NSStringLocalizedFormatKey", path=path)
                continue

            variants = {
                name for name, val in entry.items()
                if name != "NSStringLocalizedFormatKey" and isinstance(val, dict)
            }
            # A variant string can reference another variable, so follow refs until
            # no new one appears.
            refs = set(_PLURAL_REF.findall(fmt))
            todo = list(refs & variants)
            while todo:
                sub = entry[todo.pop()]
                for cat in PLURAL_CATEGORIES:
                    for ref in _PLURAL_REF.findall(str(sub.get(cat, ""))):
                        if ref not in refs:
                            refs.add(ref)
                            if ref in variants:
                                todo.append(ref)

            for ref in sorted(refs - variants):
                self.add("error", "plural-dangling-ref", lang, key,
                         f"format key references %#@{ref}@ but the only sub-dictionaries "
                         f"are {sorted(variants)} — renders the literal format key",
                         f"NSStringLocalizedFormatKey = {fmt!r}", path,
                         short=f"Refers to plural variable `{ref}`, which does not exist.")
            for unused in sorted(variants - refs):
                self.add("warning", "plural-unused-variant", lang, key,
                         f'sub-dictionary "{unused}" is never referenced by {fmt!r}',
                         path=path, short=f"Plural variable `{unused}` is never used.")

            for name in sorted(variants & refs):
                self.check_plural_variant(lang, rules_lang, key, name, entry[name], path)

            base_entry = base_dict.get(key) if base_dict is not None else None
            if isinstance(base_entry, dict):
                self.compare_plural_entry(lang, key, base_entry, entry,
                                          sorted(variants & refs), path)

    def compare_plural_entry(self, lang, key, base_entry, entry, names, path):
        """Compare placeholders and markup tokens of each plural string with Base."""
        base_fmt = base_entry.get("NSStringLocalizedFormatKey")
        fmt = entry["NSStringLocalizedFormatKey"]
        if isinstance(base_fmt, str):
            # The refs are replaced by variant text, so they are not printf slots.
            self.compare_formats(lang, key, _PLURAL_REF.sub("", base_fmt),
                                 _PLURAL_REF.sub("", fmt), path, where="format key")
            self.compare_tokens(lang, key, base_fmt, fmt, path, where="format key")

        for name in names:
            base_sub = base_entry.get(name)
            if not isinstance(base_sub, dict):
                continue
            sub = entry[name]
            base_type = base_sub.get("NSStringFormatValueTypeKey")
            got_type = sub.get("NSStringFormatValueTypeKey")
            if base_type and got_type and base_type != got_type:
                self.add("error", "format-type", lang, key,
                         f"{name}: NSStringFormatValueTypeKey is {got_type!r} but Base "
                         f"declares {base_type!r}", path=path,
                         short=f"Plural `{name}` value type is `{got_type}`, Base has "
                               f"`{base_type}`.")
            base_cats = [c for c in PLURAL_CATEGORIES if c in base_sub]
            if not base_cats:
                continue
            # A form may leave out the count ('one' -> "a file"), so a missing slot is
            # fine. Extra slots or a type change are compared with all Base forms.
            union = FormatSig({}, 0, False, set(), [])
            for cat in base_cats:
                sig = format_signature(str(base_sub[cat]))
                union.slots.update(sig.slots)
                union.wide.update(sig.wide)
            for cat in PLURAL_CATEGORIES:
                if cat not in sub or not str(sub[cat]).strip():
                    continue
                ref_cat = cat if cat in base_sub else ("other" if "other" in base_sub
                                                       else base_cats[0])
                base_text, text = str(base_sub[ref_cat]), str(sub[cat])
                where = f"{name}.{cat}"
                self.compare_formats(lang, key, base_text, text, path, where=where,
                                     allow_missing=True, base_sig=union)
                self.compare_tokens(lang, key, base_text, text, path, where=where)

    def check_plural_variant(self, lang, rules_lang, key, name, sub, path):
        if sub.get("NSStringFormatSpecTypeKey") != "NSStringPluralRuleType":
            self.add("error", "plural-malformed", lang, key,
                     f"{name}: NSStringFormatSpecTypeKey is "
                     f"{sub.get('NSStringFormatSpecTypeKey')!r}, expected NSStringPluralRuleType",
                     path=path)
        if "NSStringFormatValueTypeKey" not in sub:
            self.add("error", "plural-malformed", lang, key,
                     f"{name}: missing NSStringFormatValueTypeKey", path=path)

        present = {c for c in PLURAL_CATEGORIES if c in sub}
        for cat in sorted(present):
            if not str(sub[cat]).strip():
                self.add("error", "plural-empty-variant", lang, key,
                         f"{name}.{cat} is empty", path=path,
                         short=f"Plural `{name}.{cat}` is empty.")
                continue
            # Variant strings are formatted by the same printf pass, so they carry the
            # same '%[' hazard as flat .strings values.
            self.check_glued_percent(lang, key, str(sub[cat]), path, where=f"{name}.{cat}")

        if not present:
            self.add("error", "plural-renders-null", lang, key,
                     f"{name}: no plural variants at all — every count renders \"(null)\"",
                     path=path, short=f"Plural `{name}` has no forms. It shows \"(null)\".")
            return

        has_other = "other" in present
        broken, fallback = [], []
        for n in self.counts + self.large_counts:
            cat = plural_category(rules_lang, n)
            if cat in present:
                continue
            # Without an `other` variant there is nothing left to fall back to and
            # Foundation yields the literal string "(null)".
            (fallback if has_other else broken).append((n, cat))

        if broken:
            cats = sorted({c for _, c in broken})
            sample = ", ".join(str(n) for n, _ in broken[:12])
            self.add("error", "plural-renders-null", lang, key,
                     f'{name}: renders "(null)" for {len(broken)} probed count(s) — '
                     f"{rules_lang} needs {cats} here, but the entry only has "
                     f"{sorted(present)} and no \"other\" fallback",
                     f"failing counts: {sample}" + (" …" if len(broken) > 12 else ""),
                     path,
                     short=f"Plural `{name}` misses {_join_tokens(cats)} and has no "
                           f"`other`. It shows \"(null)\" for {broken[0][0]}.")

        if fallback:
            cats = sorted({c for _, c in fallback})
            common_hits = [n for n, _ in fallback if n in self.counts]
            if common_hits:
                self.add("warning", "plural-grammar-fallback", lang, key,
                         f"{name}: missing {cats} for {rules_lang}, so counts like "
                         f"{', '.join(str(n) for n in common_hits[:6])} fall back to "
                         f'"other" — grammatically wrong, but readable',
                         path=path,
                         short=f"Plural `{name}` misses {_join_tokens(cats)}. Some numbers "
                               f"use the `other` form.")
            else:
                self.add("info", "plural-grammar-fallback", lang, key,
                         f"{name}: missing {cats} for {rules_lang}; only reached by "
                         f"counts like {fallback[0][0]:,}, so no practical impact",
                         path=path)

        if not has_other:
            self.add("info", "plural-no-other", lang, key,
                     f'{name}: no "other" variant. Unreachable for integer counts in '
                     f"{rules_lang}, so this is currently harmless, but it is the "
                     f"fallback Apple documents as required",
                     path=path)


# --------------------------------------------------------------------------------------
# Changes-only mode
# --------------------------------------------------------------------------------------

L10N_FILES = ("Localizable.strings", "Localizable.stringsdict")


def git(args, cwd) -> str:
    proc = subprocess.run(["git", *args], cwd=cwd, capture_output=True)
    if proc.returncode != 0:
        raise RuntimeError(f"git {' '.join(args)}: "
                           f"{proc.stderr.decode('utf-8', 'replace').strip()}")
    return proc.stdout.decode("utf-8", "replace")


def _load_table(path):
    """Parsed .strings or .stringsdict, or {} when the file is missing or broken."""
    if not os.path.exists(path):
        return {}
    if path.endswith(".stringsdict"):
        table, _ = parse_stringsdict(path)
    else:
        table, _ = parse_strings(path)
    return table or {}


def _raw_counts(path):
    if not path.endswith(".strings") or not os.path.exists(path):
        return collections.Counter()
    return collections.Counter(raw_key_order(read_text(path)))


def changed_keys_between(old_path, new_path) -> set:
    """Keys that are new or have a new value in `new_path`.

    A .stringsdict key counts as changed when anything in its entry changed. A
    .strings key also counts when it is declared a different number of times.
    """
    old, new = _load_table(old_path), _load_table(new_path)
    keys = {k for k, v in new.items() if k not in old or old[k] != v}
    old_raw, new_raw = _raw_counts(old_path), _raw_counts(new_path)
    keys |= {k for k in new_raw if new_raw[k] != old_raw.get(k, 0)}
    return keys


class Change:
    """What changed under one resources root since the merge base."""

    def __init__(self):
        self.merge_base = ""
        self.base_root = ""      # the resources root as it was at the merge base
        self.files: list = []    # changed files, relative to the resources root
        self.langs: list = []
        self.keys: set = set()
        self.new_base_keys: set = set()
        self.tmp_dir = ""


def detect_changes(root, rev, base_lang="Base"):
    """Find changed keys under `root` since merge-base(rev, HEAD).

    Changes come from the working tree, which is HEAD on CI. Returns None when no
    Localizable file changed.
    """
    top = git(["rev-parse", "--show-toplevel"], root).strip()
    rel_root = os.path.relpath(os.path.realpath(root), os.path.realpath(top))
    merge_base = git(["merge-base", rev, "HEAD"], top).strip()
    specs = [f"{rel_root}/*.lproj/{name}" for name in L10N_FILES]
    names = git(["diff", "--name-only", "--diff-filter=AMR", merge_base, "--", *specs],
                top).split()
    if not names:
        return None

    change = Change()
    change.merge_base = merge_base
    change.tmp_dir = tempfile.mkdtemp(prefix="l10n_lint_base_")
    change.base_root = os.path.join(change.tmp_dir, rel_root)
    os.makedirs(change.base_root, exist_ok=True)
    archive = subprocess.run(["git", "archive", merge_base, "--", rel_root], cwd=top,
                             capture_output=True)
    if archive.returncode == 0:  # fails when the folder is new; the base stays empty
        with tarfile.open(fileobj=io.BytesIO(archive.stdout)) as tar:
            tar.extractall(change.tmp_dir)

    langs = set()
    for name in names:
        rel = os.path.relpath(name, rel_root)
        change.files.append(rel)
        langs.add(rel.split(os.sep)[0][: -len(".lproj")])
        change.keys |= changed_keys_between(os.path.join(change.base_root, rel),
                                            os.path.join(root, rel))
    change.langs = sorted(langs)

    for name in L10N_FILES:
        rel = os.path.join(f"{base_lang}.lproj", name)
        old = _load_table(os.path.join(change.base_root, rel))
        new = _load_table(os.path.join(root, rel))
        change.new_base_keys |= set(new) - set(old)
    return change


def select_changed(findings, base_findings, change):
    """Split findings on changed keys into (new, known, waiting).

    known    the same finding exists at the merge base
    waiting  missing translations of a key that is new in Base. Translations arrive
             later from Weblate, so this is normal. en is a copy of Base and must not wait.
    """
    known_prints = {f.fingerprint for f in base_findings}
    new, known, waiting = [], [], []
    for f in findings:
        if f.key not in change.keys and f.rule != "parse-error":
            continue
        if (f.rule in ("missing-key", "missing-plural-key") and f.key in change.new_base_keys
                and f.lang != SOURCE_COPY_LANG):
            waiting.append(f)
        elif f.fingerprint in known_prints:
            known.append(f)
        else:
            new.append(f)
    return new, known, waiting


# --------------------------------------------------------------------------------------
# Reporting
# --------------------------------------------------------------------------------------

RULE_ORDER = {
    "parse-error": 0, "plural-renders-null": 1, "base-accidental-conversion": 2,
    "format-arity": 3, "format-type": 4, "missing-markup-token": 5,
    "plural-dangling-ref": 6, "plural-empty-variant": 7, "empty-value": 8,
    "plural-malformed": 9, "malformed-value": 10, "percent-glued-to-token": 11,
    "unescaped-percent": 12, "unknown-markup-token": 13, "newline-differs": 14,
    "en-differs-from-base": 15, "plural-grammar-fallback": 16,
    "plural-unused-variant": 17, "duplicate-key": 18, "missing-key": 19,
    "missing-plural-key": 20, "plural-no-other": 21, "orphan-key": 22,
    "orphan-plural-key": 23, "key-in-both-tables": 24,
}


def sort_findings(findings):
    return sorted(
        findings,
        key=lambda f: (SEVERITIES.index(f.severity), RULE_ORDER.get(f.rule, 99),
                       f.lang, f.key),
    )


def render_text(findings, show_all=False) -> str:
    out = []
    by_sev = collections.defaultdict(list)
    for f in findings:
        by_sev[f.severity].append(f)

    for sev in SEVERITIES:
        items = by_sev.get(sev)
        if not items:
            continue
        out.append("")
        out.append("=" * 78)
        out.append(f"{sev.upper()}  —  {len(items)} finding(s)")
        out.append("=" * 78)
        by_rule = collections.defaultdict(list)
        for f in items:
            by_rule[f.rule].append(f)
        for rule in sorted(by_rule, key=lambda r: RULE_ORDER.get(r, 99)):
            rows = by_rule[rule]
            out.append("")
            out.append(f"[{rule}]  {len(rows)}")
            shown = rows if (show_all or sev == "error") else rows[:10]
            for f in shown:
                out.append(f"  {f.lang:<8} {f.key}")
                out.append(f"           {f.message}")
                if f.detail:
                    for line in f.detail.splitlines():
                        out.append(f"           | {line}")
            if len(shown) < len(rows):
                out.append(f"  … {len(rows) - len(shown)} more (use --show-all)")

    counts = {s: len(by_sev.get(s, [])) for s in SEVERITIES}
    out.append("")
    out.append("-" * 78)
    out.append(f"errors: {counts['error']}   warnings: {counts['warning']}   "
               f"info: {counts['info']}")
    return "\n".join(out)


def render_json(findings) -> str:
    return json.dumps([f.to_dict() for f in findings], indent=2, ensure_ascii=False)


def render_junit(findings) -> str:
    """JUnit XML so Jenkins' `junit` step renders findings as test failures."""
    by_rule = collections.defaultdict(list)
    for f in findings:
        by_rule[f.rule].append(f)

    suites = ET.Element("testsuites", name="l10n_lint")
    for rule in sorted(by_rule, key=lambda r: RULE_ORDER.get(r, 99)):
        rows = by_rule[rule]
        failures = sum(1 for f in rows if f.severity == "error")
        suite = ET.SubElement(suites, "testsuite", name=f"l10n.{rule}",
                              tests=str(len(rows)), failures=str(failures))
        for f in rows:
            case = ET.SubElement(suite, "testcase", classname=f"l10n.{rule}.{f.lang}",
                                 name=f.key)
            body = f.message + (("\n" + f.detail) if f.detail else "")
            if f.severity == "error":
                ET.SubElement(case, "failure", message=f.message, type=f.rule).text = body
            else:
                ET.SubElement(case, "skipped", message=f.message).text = body
    return ET.tostring(suites, encoding="unicode", xml_declaration=True)


GITLAB_SEVERITY = {"error": "blocker", "warning": "minor", "info": "info"}


def render_gitlab(findings) -> str:
    """GitLab Code Quality report — surfaces findings inline on the MR diff."""
    return json.dumps([
        {
            "description": f"[{f.lang}] {f.key}: {f.message}",
            "check_name": f.rule,
            "fingerprint": f.fingerprint,
            "severity": GITLAB_SEVERITY[f.severity],
            "location": {"path": f.path, "lines": {"begin": f.line or 1}},
        }
        for f in findings
    ], indent=2, ensure_ascii=False)


# -- MR comment -------------------------------------------------------------------------

MR_MARKER = "<!-- l10n-lint -->"
MR_MAX_ROWS = 20
MR_MAX_VALUE = 80
MR_MAX_LANGS = 6


def md_code(text, in_table=False) -> str:
    """A code span that keeps tags like <b> and survives a table cell."""
    text = text.replace("\n", "\\n")
    if len(text) > MR_MAX_VALUE:
        text = text[:MR_MAX_VALUE] + "…"
    if in_table:
        text = text.replace("|", "\\|")
    if "`" in text:
        return f"`` {text} ``"
    return f"`{text}`"


def _plural_word(n, one, many) -> str:
    return f"{n} {one if n == 1 else many}"


def _lang_list(langs) -> str:
    if len(langs) <= MR_MAX_LANGS:
        return ", ".join(langs)
    return ", ".join(langs[:MR_MAX_LANGS]) + f" … ({len(langs)})"


def group_rows(findings):
    """[(severity, key, rule, short, [findings])], errors first, languages merged."""
    groups = collections.OrderedDict()
    for f in sort_findings(findings):
        groups.setdefault((f.severity, f.key, f.rule, f.short), []).append(f)
    rows = [(sev, key, rule, short, items) for (sev, key, rule, short), items in groups.items()]
    return sorted(rows, key=lambda r: (SEVERITIES.index(r[0]), r[1], RULE_ORDER.get(r[2], 99)))


def _table(rows, bold_errors):
    out = ["| Key | Languages | Problem |", "|---|---|---|"]
    for sev, key, _rule, short, items in rows:
        langs = _lang_list(sorted({f.lang for f in items}))
        label = f"**{sev}**" if (bold_errors and sev == "error") else sev
        out.append(f"| {md_code(key, True)} | {langs} | {label} {_cell(short)} |")
    return out


def _cell(text) -> str:
    # Pipes split a table cell, also inside code spans.
    return text.replace("\n", " ").replace("|", "\\|")


def _waiting_line(waiting) -> str:
    if not waiting:
        return ""
    keys = {f.key for f in waiting}
    langs = {f.lang for f in waiting}
    verb = "waits" if len(keys) == 1 else "wait"
    return (f"{_plural_word(len(keys), 'new key', 'new keys')} {verb} for translation in "
            f"{_plural_word(len(langs), 'language', 'languages')}.")


def _footer(info, extra="") -> str:
    parts = [f"Commit `{info['commit']}`"]
    if extra:
        parts.append(extra)
    if info.get("report_url"):
        parts.append(f"[full report]({info['report_url']})")
    return "<sub>" + " · ".join(parts) + "</sub>"


def render_mr_no_changes(info) -> str:
    return (f"{MR_MARKER}\n#### Localization check\n"
            f"No Localizable changes in this MR any more. Commit `{info['commit']}`.\n")


def render_mr_markdown(new, known, waiting, info) -> str:
    """The MR comment. `info` has commit, base_name, changed_keys, changed_langs,
    lang_count and report_url."""
    out = [MR_MARKER]
    errors = sum(1 for f in new if f.severity == "error")
    warnings = sum(1 for f in new if f.severity == "warning")
    waiting_line = _waiting_line(waiting)
    changed = _plural_word(info["changed_keys"], "changed key", "changed keys")

    if not new:
        out.append("#### :white_check_mark: Localization check")
        out.append(f"{changed} in {_lang_list(info['changed_langs'])}. No new problems.")
        if waiting_line:
            out.append(waiting_line)
        out.append(_footer(info))
        return "\n".join(out) + "\n"

    counts = []
    if errors:
        counts.append(_plural_word(errors, "error", "errors"))
    if warnings:
        counts.append(_plural_word(warnings, "warning", "warnings"))
    icon = ":x:" if errors else ":warning:"
    out.append(f"#### {icon} Localization check: {', '.join(counts)}")
    out.append(f"Checked {changed} in {_plural_word(info['lang_count'], 'language', 'languages')}."
               f" Only problems that are not on `{info['base_name']}` are counted.")
    out.append("")

    rows = group_rows(new)
    shown = rows[:MR_MAX_ROWS]
    out.extend(_table(shown, bold_errors=True))

    values = []
    for _sev, key, _rule, _short, items in shown:
        for f in items:
            if f.value is None:
                continue
            values.append(f"- {md_code(key)} · {f.lang}")
            if f.base_value is not None:
                values.append(f"  - Base: {md_code(f.base_value)}")
            values.append(f"  - {f.lang}: {md_code(f.value)}")
    entries = sum(1 for v in values if v.startswith("- "))
    if entries:
        out.append("")
        out.append(f"<details open><summary>Values ({entries})</summary>")
        out.append("")
        out.extend(values)
        out.append("</details>")

    if known:
        known_rows = group_rows(known)
        out.append("")
        out.append(f"<details open><summary>Already on {info['base_name']} "
                   f"({len(known_rows)}, not counted)</summary>")
        out.append("")
        out.extend(_table(known_rows[:MR_MAX_ROWS], bold_errors=False))
        out.append("</details>")

    out.append("")
    showing = f"Showing {len(shown)} of {len(rows)} rows."
    if len(rows) > len(shown):
        showing += " See the full report."
    if waiting_line:
        showing += " " + waiting_line
    out.append(showing)
    out.append(_footer(info, "Report only, does not block the merge"))
    return "\n".join(out) + "\n"


# --------------------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------------------

DEFAULT_ROOTS = [
    "Modules/Presentation/MEGAL10n/Framework/MEGAL10n/MEGAL10n/Resources",
    "Modules/MEGASharedRepo/MEGASharedRepoL10n/Sources/Resources",
]


def repo_root() -> str:
    here = os.path.dirname(os.path.abspath(__file__))
    return os.path.dirname(here)


def display_root(root) -> str:
    """The root relative to the repository, so report paths work on any machine."""
    rel = os.path.relpath(os.path.abspath(root), repo_root())
    return os.path.abspath(root) if rel.startswith("..") else rel


def load_baseline(path):
    if not path or not os.path.exists(path):
        return set()
    with open(path, encoding="utf-8") as handle:
        return set(json.load(handle).get("fingerprints", []))


def build_parser():
    p = argparse.ArgumentParser(
        prog="l10n_lint",
        description="Validate Localizable.strings/.stringsdict across all languages.",
    )
    p.add_argument("--root", action="append", default=None,
                   help="Resources directory containing *.lproj (repeatable). "
                        "Defaults to the MEGAL10n and MEGASharedRepoL10n resource dirs.")
    p.add_argument("--base", default="Base", help="Name of the reference lproj (default: Base)")
    p.add_argument("--format", choices=("text", "json", "junit", "gitlab", "mr-markdown"),
                   default="text",
                   help="mr-markdown needs --changed-since")
    p.add_argument("--output", help="Write the report here instead of stdout")
    p.add_argument("--json-output", help="Also write the findings as JSON to this file")
    p.add_argument("--show-all", action="store_true",
                   help="Do not truncate warning/info lists in text output")
    p.add_argument("--min-severity", choices=SEVERITIES, default="info",
                   help="Drop findings below this severity (default: info)")
    p.add_argument("--fail-on", choices=SEVERITIES + ("never",), default="error",
                   help="Exit 1 when a finding at or above this severity survives "
                        "(default: error)")
    p.add_argument("--baseline", help="JSON file of accepted fingerprints to suppress")
    p.add_argument("--write-baseline", action="store_true",
                   help="Rewrite --baseline from the current findings, then exit 0")
    p.add_argument("--only-langs", help="Comma-separated list of languages to check")
    p.add_argument("--check-unused", action="store_true",
                   help="Cross-reference keys against Swift/ObjC sources and demote "
                        "findings on keys that appear unreferenced")
    p.add_argument("--source-root", action="append", default=None,
                   help="Source tree(s) for --check-unused (default: Modules and iMEGA)")
    p.add_argument("--changed-since", metavar="REV",
                   help="Report only keys changed since merge-base(REV, HEAD), and only "
                        "problems that are not at that merge base. Needs one --root.")
    p.add_argument("--report-url", help="Link to the full report, shown in mr-markdown")
    return p


def write_report(path, report):
    if path:
        os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
        with open(path, "w", encoding="utf-8") as handle:
            handle.write(report + ("" if report.endswith("\n") else "\n"))
    else:
        print(report)


def postprocess(findings, args, root_dir):
    """Apply --only-langs, --check-unused and --min-severity."""
    if args.only_langs:
        wanted = {s.strip() for s in args.only_langs.split(",")}
        findings = [f for f in findings if f.lang in wanted]

    if args.check_unused:
        source_roots = args.source_root or [
            os.path.join(root_dir, "Modules"), os.path.join(root_dir, "iMEGA")
        ]
        idents = collect_source_identifiers([r for r in source_roots if os.path.isdir(r)])
        for f in findings:
            leaf = key_leaf(f.key)
            if leaf and leaf not in idents and f.severity == "error":
                f.severity = "info"
                f.message += "  [key appears unreferenced in source]"

    cutoff = SEVERITIES.index(args.min_severity)
    findings = [f for f in findings if SEVERITIES.index(f.severity) <= cutoff]
    return sort_findings(findings)


def exit_code(findings, fail_on):
    if fail_on == "never":
        return 0
    if any(f.rule == "parse-error" for f in findings):
        return 2
    threshold = SEVERITIES.index(fail_on)
    blocking = [f for f in findings if SEVERITIES.index(f.severity) <= threshold]
    if blocking:
        print(f"l10n_lint: {len(blocking)} blocking finding(s)", file=sys.stderr)
        return 1
    return 0


def run_changed(args, root, root_dir):
    """--changed-since: lint one root and keep only problems on changed keys."""
    label = display_root(root)
    commit = git(["rev-parse", "--short", "HEAD"], root).strip()
    base_name = args.changed_since.split("/")[-1]
    change = detect_changes(root, args.changed_since, args.base)
    if change is None:
        print(f"l10n_lint: no Localizable file changed since {args.changed_since}",
              file=sys.stderr)
        if args.format == "mr-markdown":
            write_report(args.output, render_mr_no_changes({"commit": commit}))
        if args.json_output:
            write_report(args.json_output, render_json([]))
        return 0
    try:
        head = Linter(root, base=args.base, label=label)
        findings = postprocess(head.run(), args, root_dir)
        base_findings = []
        if os.path.isdir(os.path.join(change.base_root, f"{args.base}.lproj")):
            base_findings = postprocess(
                Linter(change.base_root, base=args.base, label=label).run(), args, root_dir)
    finally:
        shutil.rmtree(change.tmp_dir, ignore_errors=True)

    new, known, waiting = select_changed(findings, base_findings, change)
    if args.json_output:
        write_report(args.json_output, render_json(new + known))
    if args.format == "mr-markdown":
        info = {
            "commit": commit,
            "base_name": base_name,
            "changed_keys": len(change.keys),
            "changed_langs": change.langs,
            "lang_count": len(head.languages()),
            "report_url": args.report_url,
        }
        report = render_mr_markdown(new, known, waiting, info)
    else:
        report = {"text": lambda fs: render_text(fs, args.show_all),
                  "json": render_json, "junit": render_junit,
                  "gitlab": render_gitlab}[args.format](new)
    write_report(args.output, report)
    print(f"l10n_lint: {len(change.keys)} changed key(s), {len(new)} new problem(s), "
          f"{len(known)} known, {len(waiting)} waiting for translation", file=sys.stderr)
    return exit_code(new, args.fail_on)


def main(argv=None) -> int:
    args = build_parser().parse_args(argv)
    root_dir = repo_root()
    if args.root:
        missing = [r for r in args.root if not os.path.isdir(r)]
        if missing:
            print(f"l10n_lint: resource directory not found: {', '.join(missing)}",
                  file=sys.stderr)
            return 2
        roots = args.root
    else:
        roots = []
        for rel in DEFAULT_ROOTS:
            path = os.path.join(root_dir, rel)
            if os.path.isdir(path):
                roots.append(path)
            else:
                print(f"l10n_lint: skipped {rel}: not found", file=sys.stderr)
    if not roots:
        print("l10n_lint: no resource directories found", file=sys.stderr)
        return 2
    if args.format == "mr-markdown" and not args.changed_since:
        print("l10n_lint: --format mr-markdown needs --changed-since", file=sys.stderr)
        return 2

    if args.changed_since:
        if len(roots) != 1:
            print("l10n_lint: --changed-since needs exactly one --root", file=sys.stderr)
            return 2
        try:
            return run_changed(args, roots[0], root_dir)
        except Exception as exc:
            print(f"l10n_lint: failed scanning {roots[0]}: {exc}", file=sys.stderr)
            return 2

    findings = []
    for root in roots:
        linter = Linter(root, base=args.base, label=display_root(root))
        try:
            findings.extend(linter.run())
        except Exception as exc:  # pragma: no cover - defensive
            print(f"l10n_lint: failed scanning {root}: {exc}", file=sys.stderr)
            return 2

    findings = postprocess(findings, args, root_dir)

    if args.write_baseline:
        if not args.baseline:
            print("l10n_lint: --write-baseline requires --baseline", file=sys.stderr)
            return 2
        payload = {
            "note": "Fingerprints accepted as pre-existing. Delete an entry to re-surface it.",
            "fingerprints": sorted({f.fingerprint for f in findings}),
        }
        with open(args.baseline, "w", encoding="utf-8") as handle:
            json.dump(payload, handle, indent=2)
            handle.write("\n")
        print(f"l10n_lint: wrote {len(payload['fingerprints'])} fingerprints "
              f"to {args.baseline}")
        return 0

    baseline = load_baseline(args.baseline)
    if baseline:
        before = len(findings)
        findings = [f for f in findings if f.fingerprint not in baseline]
        print(f"l10n_lint: baseline suppressed {before - len(findings)} known finding(s)",
              file=sys.stderr)

    renderer = {"text": lambda fs: render_text(fs, args.show_all),
                "json": render_json, "junit": render_junit,
                "gitlab": render_gitlab}[args.format]
    write_report(args.output, renderer(findings))
    if args.json_output:
        write_report(args.json_output, render_json(findings))
    return exit_code(findings, args.fail_on)


if __name__ == "__main__":
    sys.exit(main())
