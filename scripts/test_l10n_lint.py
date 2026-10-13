#!/usr/bin/env python3
"""
Tests for l10n_lint.

The plural-rule expectations are not copied from the CLDR tables — they are the
categories Foundation itself selected when the real MEGA .stringsdict files were
rendered through CFBundle with each locale bound. That makes them ground truth for
the behaviour we actually care about.

Run:  python3 -m unittest discover -s scripts -p 'test_*.py' -v
"""

import json
import os
import plistlib
import shutil
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import l10n_lint as L  # noqa: E402


# ======================================================================================
# Fixture helpers
# ======================================================================================

def write_strings(root, lang, mapping):
    d = os.path.join(root, f"{lang}.lproj")
    os.makedirs(d, exist_ok=True)
    lines = []
    for key, value in mapping.items():
        esc = value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
        lines.append(f'"{key}" = "{esc}";')
    with open(os.path.join(d, "Localizable.strings"), "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines) + "\n")


def write_stringsdict(root, lang, mapping):
    d = os.path.join(root, f"{lang}.lproj")
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, "Localizable.stringsdict"), "wb") as fh:
        plistlib.dump(mapping, fh)


def plural_entry(variants, value_type="d", var="count"):
    sub = {"NSStringFormatSpecTypeKey": "NSStringPluralRuleType",
           "NSStringFormatValueTypeKey": value_type}
    sub.update(variants)
    return {"NSStringLocalizedFormatKey": f"%#@{var}@", var: sub}


def run_linter(root, base="Base"):
    return L.Linter(root, base=base).run()


def rules_of(findings, rule):
    return [f for f in findings if f.rule == rule]


def errors(findings):
    return [f for f in findings if f.severity == "error"]


# ======================================================================================
# Plural rule engine — ground truth from Foundation
# ======================================================================================

class TestPluralRules(unittest.TestCase):
    """Each case below was confirmed by rendering the real files through CFBundle."""

    def assert_cats(self, lang, expected):
        for n, cat in expected.items():
            with self.subTest(lang=lang, n=n):
                self.assertEqual(L.plural_category(lang, n), cat)

    def test_russian(self):
        # ru "general.format.count.file": 1→файл(one) 2→файла(few) 5→файлов(many)
        #                                 22→файла(few) 100→файлов(many)
        self.assert_cats("ru", {
            1: "one", 21: "one", 101: "one",
            2: "few", 3: "few", 4: "few", 22: "few", 23: "few", 104: "few",
            0: "many", 5: "many", 11: "many", 12: "many", 13: "many", 14: "many",
            19: "many", 100: "many",
        })

    def test_polish(self):
        # pl countdown.hours has only {few, many}: 1→(null) 2,3,4→few 5→many 22→few
        self.assert_cats("pl", {
            1: "one",
            2: "few", 3: "few", 4: "few", 22: "few", 23: "few", 24: "few",
            0: "many", 5: "many", 12: "many", 13: "many", 14: "many", 21: "many",
            25: "many", 100: "many",
        })

    def test_romanian(self):
        # ro "general.format.count.file": 1→fișier 2..12→fișiere 22→"de fișiere" 100→"de fișiere"
        self.assert_cats("ro", {
            1: "one",
            0: "few", 2: "few", 12: "few", 19: "few", 101: "few", 119: "few",
            20: "other", 22: "other", 100: "other", 120: "other",
        })

    def test_arabic(self):
        self.assert_cats("ar", {
            0: "zero", 1: "one", 2: "two",
            3: "few", 10: "few", 103: "few",
            11: "many", 99: "many", 111: "many",
            100: "other", 102: "other", 200: "other",
        })

    def test_french_and_portuguese_treat_zero_as_one(self):
        # fr countdown: 1→Heure(one) 2→Heures(other);  pt: 1→hora(one) 2→horas(other)
        for lang in ("fr", "pt"):
            self.assert_cats(lang, {0: "one", 1: "one", 2: "other", 100: "other",
                                    1_000_000: "many"})

    def test_spanish_and_italian_zero_is_other(self):
        for lang in ("es", "it"):
            self.assert_cats(lang, {0: "other", 1: "one", 2: "other",
                                    1_000_000: "many"})

    def test_germanic_one_other(self):
        for lang in ("en", "de", "nl", "tr"):
            self.assert_cats(lang, {0: "other", 1: "one", 2: "other", 100: "other"})

    def test_other_only_languages(self):
        # id/th/vi/ja/ko/zh countdown rendered the same string for every count
        for lang in ("id", "th", "vi", "ja", "ko", "zh-Hans", "zh-Hant"):
            self.assert_cats(lang, {0: "other", 1: "other", 2: "other", 100: "other"})

    def test_other_is_unreachable_for_integers_in_pl_and_ru(self):
        """The reason 223 pl/ru entries ship without `other` and still render fine."""
        for lang in ("pl", "ru"):
            cats = {L.plural_category(lang, n) for n in range(0, 1000)}
            self.assertNotIn("other", cats, f"{lang} unexpectedly reached `other`")

    def test_unknown_language_falls_back_to_one_other(self):
        self.assertEqual(L.plural_category("xx", 1), "one")
        self.assertEqual(L.plural_category("xx", 5), "other")


# ======================================================================================
# printf signature model
# ======================================================================================

class TestFormatSignature(unittest.TestCase):
    def test_plain_text_has_no_slots(self):
        sig = L.format_signature("Hello world")
        self.assertEqual(sig.slots, {})
        self.assertEqual(sig.bare, 0)

    def test_sequential_specifiers_number_from_one(self):
        sig = L.format_signature("%@ of %@ used")
        self.assertEqual(sig.slots, {1: "@", 2: "@"})
        self.assertFalse(sig.positional)

    def test_positional_specifiers(self):
        sig = L.format_signature("%1$@: %2$@ off")
        self.assertEqual(sig.slots, {1: "@", 2: "@"})
        self.assertTrue(sig.positional)

    def test_escaped_percent_is_not_a_slot(self):
        sig = L.format_signature("Your storage is %d%% full")
        self.assertEqual(sig.slots, {1: "d"})
        self.assertEqual(sig.bare, 0)

    def test_single_percent_before_letter_becomes_a_conversion(self):
        """The Romanian bug: '%d% plin' -> '%d' plus '% p' (a pointer conversion)."""
        sig = L.format_signature("Spațiul este %d% plin")
        self.assertEqual(sig.slots, {1: "d", 2: "p"})

    def test_single_percent_before_d_becomes_a_conversion(self):
        sig = L.format_signature("Ai folosit %d% din cota")
        self.assertEqual(sig.slots, {1: "d", 2: "d"})

    def test_trailing_percent_is_bare(self):
        sig = L.format_signature("заполнено на %d%")
        self.assertEqual(sig.slots, {1: "d"})
        self.assertEqual(sig.bare, 1)

    def test_percent_before_non_conversion_is_bare(self):
        sig = L.format_signature("потратили %d% вашего")
        self.assertEqual(sig.slots, {1: "d"})
        self.assertEqual(sig.bare, 1)

    def test_lost_positional_markers(self):
        """ru specialOfferLabel: '%1: скидка %2' has no conversions at all."""
        sig = L.format_signature("%1: скидка %2")
        self.assertEqual(sig.slots, {})
        self.assertEqual(sig.bare, 2)

    def test_width_is_not_mistaken_for_a_position(self):
        sig = L.format_signature("%10d items")
        self.assertEqual(sig.slots, {1: "d"})

    def test_c_string_conversion_detected(self):
        self.assertEqual(L.format_signature("Added to %s").slots, {1: "s"})

    def test_length_modifiers(self):
        self.assertEqual(L.format_signature("%lld and %llu").slots, {1: "d", 2: "u"})

    def test_precision(self):
        self.assertEqual(L.format_signature("%.2f%%").slots, {1: "f"})


# ======================================================================================
# Detectors — synthetic fixtures
# ======================================================================================

class LinterTestCase(unittest.TestCase):
    def setUp(self):
        self.root = tempfile.mkdtemp(prefix="l10n_test_")
        self.addCleanup(shutil.rmtree, self.root, True)

    def base(self, strings=None, sdict=None):
        write_strings(self.root, "Base", strings or {})
        write_stringsdict(self.root, "Base", sdict or {})

    def lang(self, code, strings=None, sdict=None):
        write_strings(self.root, code, strings or {})
        write_stringsdict(self.root, code, sdict or {})


class TestCleanInput(LinterTestCase):
    def test_matching_translation_produces_nothing(self):
        self.base({"greeting": "Hello %@", "count": "%d files"})
        self.lang("de", {"greeting": "Hallo %@", "count": "%d Dateien"})
        self.assertEqual(run_linter(self.root), [])

    def test_correct_plurals_produce_nothing(self):
        entry_en = plural_entry({"one": "%d file", "other": "%d files"})
        entry_de = plural_entry({"one": "%d Datei", "other": "%d Dateien"})
        self.base(sdict={"files": entry_en})
        self.lang("de", sdict={"files": entry_de})
        self.assertEqual(run_linter(self.root), [])


class TestFormatChecks(LinterTestCase):
    def test_lost_placeholders_are_errors(self):
        """Regression: ru '%1: скидка %2' for '%1$@: %2$@ off'."""
        self.base({"offer": "%1$@: %2$@ off"})
        self.lang("ru", {"offer": "%1: скидка %2"})
        found = rules_of(run_linter(self.root), "format-arity")
        self.assertEqual(len(found), 1)
        self.assertEqual(found[0].severity, "error")
        self.assertIn("drops placeholder", found[0].message)

    def test_extra_slot_from_stray_percent_is_an_error(self):
        """Regression: ro 'este %d% plin' for 'is %d%% full'."""
        self.base({"full": "Your storage is %d%% full"})
        self.lang("ro", {"full": "Spațiul dvs. de stocare este %d% plin"})
        found = rules_of(run_linter(self.root), "format-arity")
        self.assertEqual(len(found), 1)
        self.assertEqual(found[0].severity, "error")
        self.assertIn("reads past the end", found[0].message)

    def test_c_string_where_object_expected(self):
        """Regression: pt/zh-Hans 'Adicionada a %s' for 'Added to %@'."""
        self.base({"added": "Added to %@"})
        self.lang("pt", {"added": "Adicionada a %s"})
        found = rules_of(run_linter(self.root), "format-type")
        self.assertEqual(len(found), 1)
        self.assertIn("C string", found[0].message)

    def test_swapped_conversion_type(self):
        self.base({"n": "%d items"})
        self.lang("de", {"n": "%@ Artikel"})
        self.assertEqual(len(rules_of(run_linter(self.root), "format-type")), 1)

    def test_unescaped_percent_is_a_warning_not_an_error(self):
        """Regression: ru 'заполнено на %d%' — the % sign vanishes but nothing crashes."""
        self.base({"full": "Your storage is %d%% full"})
        self.lang("ru", {"full": "Ваше хранилище заполнено на %d%"})
        found = rules_of(run_linter(self.root), "unescaped-percent")
        self.assertEqual(len(found), 1)
        self.assertEqual(found[0].severity, "warning")
        self.assertEqual(errors(run_linter(self.root)), [])

    def test_positional_reorder_is_allowed(self):
        self.base({"x": "%1$@ of %2$@"})
        self.lang("ja", {"x": "%2$@ の %1$@"})
        self.assertEqual(run_linter(self.root), [])

    def test_empty_translation_is_an_error(self):
        self.base({"x": "Hello"})
        self.lang("de", {"x": "   "})
        self.assertEqual(len(rules_of(run_linter(self.root), "empty-value")), 1)


# ======================================================================================
# MEGA bracket markup tokens
# ======================================================================================

class TestBracketTokenParsing(unittest.TestCase):
    def test_tokens_are_counted_as_a_multiset(self):
        self.assertEqual(
            L.bracket_tokens("[A]link[/A] and [B]"),
            {"[A]": 1, "[/A]": 1, "[B]": 1},
        )

    def test_bare_numeric_brackets_are_not_tokens(self):
        self.assertEqual(L.bracket_tokens("see footnote [1]"), {})

    def test_glued_percent_is_detected(self):
        self.assertEqual(L.percent_glued_tokens("%d/%[A] đã hoàn tất"), ["[A]"])

    def test_escaped_percent_before_a_token_is_legitimate(self):
        self.assertEqual(L.percent_glued_tokens("100%%[A]off[/A]"), [])

    def test_untouched_token_is_not_flagged(self):
        self.assertEqual(L.percent_glued_tokens("%d of [A] completed"), [])

    def test_conversion_immediately_before_a_token_is_not_flagged(self):
        self.assertEqual(L.percent_glued_tokens("%d[A]x[/A]"), [])

    def test_every_glued_token_is_reported(self):
        self.assertEqual(L.percent_glued_tokens("%[A]a%[/A]"), ["[A]", "[/A]"])


class TestBracketTokenChecks(LinterTestCase):
    def test_percent_glued_to_token_is_a_warning(self):
        """vi '%d/%[A] đã hoàn tất': Foundation drops the '%' and keeps '[A]' intact."""
        self.base({"sub": "%d of [A] completed"})
        self.lang("vi", {"sub": "%d/%[A] đã hoàn tất"})
        found = rules_of(run_linter(self.root), "percent-glued-to-token")
        self.assertEqual(len(found), 1)
        self.assertEqual(found[0].severity, "warning")
        self.assertEqual(found[0].lang, "vi")
        self.assertIn("[A]", found[0].message)

    def test_glued_percent_is_not_also_reported_as_a_bare_percent_warning(self):
        """The single defect must produce exactly one finding, not an error and a warning."""
        self.base({"sub": "%d of [A] completed"})
        self.lang("vi", {"sub": "%d/%[A] đã hoàn tất"})
        self.assertEqual(rules_of(run_linter(self.root), "unescaped-percent"), [])

    def test_a_real_stray_percent_still_warns_alongside_a_glued_one(self):
        self.base({"sub": "[A] done"})
        self.lang("vi", {"sub": "%[A] xong 50%"})
        found = run_linter(self.root)
        self.assertEqual(len(rules_of(found, "percent-glued-to-token")), 1)
        self.assertEqual(len(rules_of(found, "unescaped-percent")), 1)

    def test_glued_percent_in_base_is_reported_too(self):
        self.base({"sub": "%[A] completed"})
        found = rules_of(run_linter(self.root), "percent-glued-to-token")
        self.assertEqual([f.lang for f in found], ["Base"])

    def test_glued_percent_inside_a_plural_variant_is_reported(self):
        self.base(sdict={"n": plural_entry({"one": "[A] file", "other": "[A] files"})})
        self.lang("vi", sdict={"n": plural_entry({"other": "%[A] tệp"})})
        found = rules_of(run_linter(self.root), "percent-glued-to-token")
        self.assertEqual(len(found), 1)
        self.assertEqual(found[0].severity, "warning")
        self.assertIn("count.other", found[0].message)

    def test_dropped_markup_token_is_an_error(self):
        """A lost [/A] silently collapses subString(from:to:) to an empty link range."""
        self.base({"learn": "Quota reached. [A]Learn more.[/A]"})
        self.lang("de", {"learn": "Kontingent erreicht. [A]Mehr erfahren."})
        found = rules_of(run_linter(self.root), "missing-markup-token")
        self.assertEqual(len(found), 1)
        self.assertEqual(found[0].severity, "error")
        self.assertIn("[/A]", found[0].message)

    def test_intact_tokens_produce_nothing(self):
        self.base({"learn": "Quota reached. [A]Learn more.[/A]"})
        self.lang("de", {"learn": "Kontingent erreicht. [A]Mehr erfahren.[/A]"})
        self.assertEqual(run_linter(self.root), [])

    def test_reordered_tokens_are_fine(self):
        self.base({"x": "[A]one[/A] then [B]two[/B]"})
        self.lang("ja", {"x": "[B]two[/B] のあと [A]one[/A]"})
        self.assertEqual(run_linter(self.root), [])

    def test_surplus_brackets_in_a_translation_are_not_reported(self):
        """Ordinary bracketed prose in the target language must not become noise."""
        self.base({"x": "Done"})
        self.lang("de", {"x": "Fertig [siehe Hinweis]"})
        self.assertEqual(rules_of(run_linter(self.root), "missing-markup-token"), [])

    def test_repeated_token_dropped_once_is_reported(self):
        self.base({"x": "[A]a[/A] and [A]b[/A]"})
        self.lang("de", {"x": "[A]a[/A] und b"})
        found = rules_of(run_linter(self.root), "missing-markup-token")
        self.assertEqual(len(found), 1)
        self.assertIn("[A]", found[0].message)


class TestKeySetChecks(LinterTestCase):
    def test_missing_key_is_reported(self):
        self.base({"a": "A", "b": "B"})
        self.lang("de", {"a": "A"})
        found = rules_of(run_linter(self.root), "missing-key")
        self.assertEqual([f.key for f in found], ["b"])

    def test_orphan_key_is_info_only(self):
        self.base({"a": "A"})
        self.lang("de", {"a": "A", "stale": "X"})
        found = rules_of(run_linter(self.root), "orphan-key")
        self.assertEqual([f.key for f in found], ["stale"])
        self.assertEqual(found[0].severity, "info")

    def test_duplicate_key_detected_from_raw_text(self):
        self.base({"a": "A"})
        d = os.path.join(self.root, "de.lproj")
        os.makedirs(d, exist_ok=True)
        with open(os.path.join(d, "Localizable.strings"), "w", encoding="utf-8") as fh:
            fh.write('"a" = "first";\n"a" = "second";\n')
        write_stringsdict(self.root, "de", {})
        found = rules_of(run_linter(self.root), "duplicate-key")
        self.assertEqual(len(found), 1)
        self.assertIn("declared 2 times", found[0].message)

    def test_base_itself_is_not_compared_against_itself(self):
        self.base({"a": "A %@"})
        self.assertEqual(run_linter(self.root), [])


class TestPluralChecks(LinterTestCase):
    def test_empty_variant_dict_renders_null(self):
        """Regression: id/th/vi intro-offer pricing keys have metadata but no variants."""
        self.base(sdict={"p": plural_entry({"one": "a", "other": "b"})})
        self.lang("id", sdict={"p": plural_entry({})})
        found = rules_of(run_linter(self.root), "plural-renders-null")
        self.assertEqual(len(found), 1)
        self.assertEqual(found[0].severity, "error")
        self.assertIn("no plural variants at all", found[0].message)

    def test_missing_reachable_category_without_other_is_an_error(self):
        """Regression: ru countdown.hours ships only `many`."""
        self.base(sdict={"h": plural_entry({"one": "Hour", "other": "Hours"})})
        self.lang("ru", sdict={"h": plural_entry({"many": "Часы"})})
        found = rules_of(run_linter(self.root), "plural-renders-null")
        self.assertEqual(len(found), 1)
        self.assertEqual(found[0].severity, "error")
        # 1 (one) and 2-4 (few) must be named as failing
        self.assertIn("one", found[0].message)
        self.assertIn("few", found[0].message)

    def test_polish_missing_only_one_is_still_an_error(self):
        """pl countdown.hours has few+many; count=1 renders (null)."""
        self.base(sdict={"h": plural_entry({"one": "Hour", "other": "Hours"})})
        self.lang("pl", sdict={"h": plural_entry({"few": "Godzina", "many": "Godziny"})})
        found = rules_of(run_linter(self.root), "plural-renders-null")
        self.assertEqual(len(found), 1)
        self.assertIn("failing counts: 1", found[0].detail)

    def test_missing_other_but_all_integers_covered_is_not_an_error(self):
        """The false positive this tool exists to avoid: pl/ru ordinary plural keys."""
        self.base(sdict={"f": plural_entry({"one": "%d file", "other": "%d files"})})
        for lang, variants in (
            ("ru", {"one": "%d файл", "few": "%d файла", "many": "%d файлов"}),
            ("pl", {"one": "%d plik", "few": "%d pliki", "many": "%d plików"}),
        ):
            self.lang(lang, sdict={"f": plural_entry(variants)})
        found = run_linter(self.root)
        self.assertEqual(errors(found), [], "pl/ru complete integer coverage must not error")
        no_other = rules_of(found, "plural-no-other")
        self.assertEqual(len(no_other), 2)
        self.assertTrue(all(f.severity == "info" for f in no_other))

    def test_grammar_fallback_is_a_warning(self):
        """de countdown has only `other`; count=1 renders '1 Tage'."""
        self.base(sdict={"d": plural_entry({"one": "Day", "other": "Days"})})
        self.lang("de", sdict={"d": plural_entry({"other": "Tage"})})
        found = run_linter(self.root)
        self.assertEqual(errors(found), [])
        warn = rules_of(found, "plural-grammar-fallback")
        self.assertEqual(len(warn), 1)
        self.assertEqual(warn[0].severity, "warning")

    def test_other_only_language_with_other_only_is_clean(self):
        self.base(sdict={"d": plural_entry({"one": "Day", "other": "Days"})})
        self.lang("th", sdict={"d": plural_entry({"other": "วัน"})})
        self.assertEqual(run_linter(self.root), [])

    def test_dangling_format_key_reference(self):
        """Regression: nl format key '%#@dagen@' with a sub-dictionary named 'days'."""
        self.base(sdict={"d": plural_entry({"one": "day", "other": "days"})})
        entry = plural_entry({"one": "dag", "other": "dagen"})
        entry["NSStringLocalizedFormatKey"] = "%#@dagen@"
        self.lang("nl", sdict={"d": entry})
        found = run_linter(self.root)
        dangling = rules_of(found, "plural-dangling-ref")
        unused = rules_of(found, "plural-unused-variant")
        self.assertEqual(len(dangling), 1)
        self.assertEqual(dangling[0].severity, "error")
        self.assertEqual(len(unused), 1)

    def test_missing_spec_type_key(self):
        self.base(sdict={"d": plural_entry({"one": "a", "other": "b"})})
        entry = plural_entry({"one": "a", "other": "b"})
        del entry["count"]["NSStringFormatValueTypeKey"]
        entry["count"]["NSStringFormatSpecTypeKey"] = "NSStringWrongRuleType"
        self.lang("de", sdict={"d": entry})
        found = rules_of(run_linter(self.root), "plural-malformed")
        self.assertEqual(len(found), 2)

    def test_empty_plural_variant_string(self):
        self.base(sdict={"d": plural_entry({"one": "a", "other": "b"})})
        self.lang("de", sdict={"d": plural_entry({"one": "", "other": "b"})})
        self.assertEqual(len(rules_of(run_linter(self.root), "plural-empty-variant")), 1)

    def test_gap_only_reachable_at_a_million_is_info_not_a_merge_blocker(self):
        """es/fr/it/pt `many` only fires at 10^6; `other` still covers it."""
        self.base(sdict={"f": plural_entry({"one": "%d file", "other": "%d files"})})
        self.lang("es", sdict={"f": plural_entry({"one": "%d archivo",
                                                  "other": "%d archivos"})})
        found = run_linter(self.root)
        self.assertEqual(errors(found), [])
        fb = rules_of(found, "plural-grammar-fallback")
        self.assertEqual(len(fb), 1)
        self.assertEqual(fb[0].severity, "info")
        self.assertIn("many", fb[0].message)

    def test_category_gap_without_other_is_an_error_at_any_magnitude(self):
        """No `other` means Foundation has nothing to fall back to."""
        self.base(sdict={"f": plural_entry({"one": "%d file", "other": "%d files"})})
        self.lang("es", sdict={"f": plural_entry({"one": "%d archivo",
                                                  "few": "%d archivos"})})
        found = rules_of(run_linter(self.root), "plural-renders-null")
        self.assertEqual(len(found), 1)
        self.assertEqual(found[0].severity, "error")


class TestParseFailures(LinterTestCase):
    def test_malformed_strings_file_is_an_error(self):
        self.base({"a": "A"})
        d = os.path.join(self.root, "de.lproj")
        os.makedirs(d, exist_ok=True)
        with open(os.path.join(d, "Localizable.strings"), "w", encoding="utf-8") as fh:
            fh.write('"a" = "unterminated;\n')
        write_stringsdict(self.root, "de", {})
        found = rules_of(run_linter(self.root), "parse-error")
        self.assertEqual(len(found), 1)

    def test_malformed_stringsdict_is_an_error(self):
        self.base({"a": "A"})
        write_strings(self.root, "de", {"a": "A"})
        with open(os.path.join(self.root, "de.lproj", "Localizable.stringsdict"), "w") as fh:
            fh.write("<not a plist>")
        found = rules_of(run_linter(self.root), "parse-error")
        self.assertEqual(len(found), 1)


# ======================================================================================
# Reporting, baseline, CLI contract
# ======================================================================================

class TestReporting(LinterTestCase):
    def make_findings(self):
        self.base({"offer": "%1$@: %2$@ off", "ok": "Fine"})
        self.lang("ru", {"offer": "%1: скидка %2", "ok": "Хорошо"})
        return L.sort_findings(run_linter(self.root))

    def test_fingerprint_names_the_problem(self):
        a = L.Finding("error", "format-arity", "ru", "offer", "one message")
        same = L.Finding("error", "format-arity", "ru", "offer", "one message")
        other_problem = L.Finding("error", "format-arity", "ru", "offer", "a different message")
        other_lang = L.Finding("error", "format-arity", "de", "offer", "one message")
        other_file = L.Finding("error", "format-arity", "ru", "offer", "one message", path="x")
        self.assertEqual(a.fingerprint, same.fingerprint)
        self.assertNotEqual(a.fingerprint, other_problem.fingerprint)
        self.assertNotEqual(a.fingerprint, other_lang.fingerprint)
        self.assertNotEqual(a.fingerprint, other_file.fingerprint)

    def test_fingerprint_survives_check_unused_message_edit(self):
        f = L.Finding("error", "format-arity", "ru", "offer", "one message")
        before = f.fingerprint
        f.message += "  [key appears unreferenced in source]"
        self.assertEqual(f.fingerprint, before)

    def test_errors_sort_before_warnings(self):
        self.base({"a": "%d%% x", "b": "%@"})
        self.lang("ru", {"a": "%d%", "b": "%s"})
        sev = [f.severity for f in L.sort_findings(run_linter(self.root))]
        self.assertEqual(sev, sorted(sev, key=L.SEVERITIES.index))

    def test_json_output_is_valid_and_complete(self):
        data = json.loads(L.render_json(self.make_findings()))
        self.assertTrue(data)
        for row in data:
            self.assertEqual(
                set(row),
                {"fingerprint", "severity", "rule", "lang", "key", "message",
                 "detail", "path", "line"},
            )

    def test_junit_output_marks_errors_as_failures(self):
        import xml.etree.ElementTree as ET
        xml = L.render_junit(self.make_findings())
        tree = ET.fromstring(xml)
        self.assertEqual(tree.tag, "testsuites")
        self.assertTrue(tree.findall(".//failure"))

    def test_gitlab_output_shape(self):
        rows = json.loads(L.render_gitlab(self.make_findings()))
        self.assertTrue(rows)
        for row in rows:
            self.assertIn(row["severity"], {"blocker", "minor", "info"})
            self.assertIn("fingerprint", row)
            self.assertIn("location", row)

    def test_text_output_mentions_the_key(self):
        text = L.render_text(self.make_findings())
        self.assertIn("offer", text)
        self.assertIn("ERROR", text)


class TestCLI(LinterTestCase):
    def setUp(self):
        super().setUp()
        self.base({"offer": "%1$@: %2$@ off"})
        self.lang("ru", {"offer": "%1: скидка %2"})

    def invoke(self, *args):
        return L.main(["--root", self.root, *args])

    def test_exit_1_on_error(self):
        self.assertEqual(self.invoke("--format", "json", "--output",
                                     os.path.join(self.root, "r.json")), 1)

    def test_exit_0_when_clean(self):
        clean = tempfile.mkdtemp(prefix="l10n_clean_")
        self.addCleanup(shutil.rmtree, clean, True)
        write_strings(clean, "Base", {"a": "A"})
        write_stringsdict(clean, "Base", {})
        write_strings(clean, "de", {"a": "A"})
        write_stringsdict(clean, "de", {})
        self.assertEqual(L.main(["--root", clean]), 0)

    def test_fail_on_never_always_exits_zero(self):
        self.assertEqual(self.invoke("--fail-on", "never"), 0)

    def test_min_severity_filters_output(self):
        out = os.path.join(self.root, "r.json")
        self.invoke("--min-severity", "error", "--format", "json", "--output", out)
        with open(out, encoding="utf-8") as fh:
            data = json.load(fh)
        self.assertTrue(all(r["severity"] == "error" for r in data))

    def test_baseline_roundtrip_suppresses_known_findings(self):
        baseline = os.path.join(self.root, "baseline.json")
        self.assertEqual(self.invoke("--baseline", baseline, "--write-baseline"), 0)
        self.assertTrue(os.path.exists(baseline))
        # Everything is now known -> clean exit.
        self.assertEqual(self.invoke("--baseline", baseline), 0)

    def test_baseline_still_catches_a_new_finding(self):
        baseline = os.path.join(self.root, "baseline.json")
        self.invoke("--baseline", baseline, "--write-baseline")
        write_strings(self.root, "de", {"offer": "%1$@ nur %2"})  # brand new breakage
        write_stringsdict(self.root, "de", {})
        self.assertEqual(self.invoke("--baseline", baseline), 1)

    def test_only_langs_narrows_the_scan(self):
        write_strings(self.root, "de", {"offer": "%1 kaputt %2"})
        write_stringsdict(self.root, "de", {})
        out = os.path.join(self.root, "r.json")
        self.invoke("--only-langs", "de", "--format", "json", "--output", out)
        with open(out, encoding="utf-8") as fh:
            self.assertEqual({r["lang"] for r in json.load(fh)}, {"de"})

    def test_missing_root_exits_2(self):
        self.assertEqual(L.main(["--root", os.path.join(self.root, "nope")]), 2)


class TestUnusedKeyHeuristic(unittest.TestCase):
    def test_key_leaf_extraction(self):
        self.assertEqual(L.key_leaf("upgradeAccountPlan.plan.tag.specialOfferLabel"),
                         "specialOfferLabel")
        self.assertEqual(L.key_leaf("twoMonthsFree"), "twoMonthsFree")

    def test_leaf_is_lowercased_like_swiftgen(self):
        self.assertEqual(L.key_leaf("a.b.SomeThing"), "someThing")

    def test_legacy_keys_are_not_guessed(self):
        self.assertIsNone(L.key_leaf("Chat created on %s1"))
        self.assertIsNone(L.key_leaf("some key with spaces"))


# ======================================================================================
# Base self-checks and the Foundation printf model
# ======================================================================================

class TestBaseChecks(LinterTestCase):
    def test_space_flag_conversion_in_base_is_one_base_error(self):
        """twoMonthsFree: Base '16% cheaper' is read as '% c'. Translations are correct."""
        self.base({"twoMonthsFree": "An annual subscription is 16% cheaper"})
        self.lang("ja", {"twoMonthsFree": "年間サブスクリプションは16 %安いです"})
        self.lang("de", {"twoMonthsFree": "Ein Jahresabo ist 16 % günstiger"})
        found = run_linter(self.root)
        self.assertEqual([(f.rule, f.lang) for f in errors(found)],
                         [("base-accidental-conversion", "Base")])
        self.assertIn("% c", found[0].message)

    def test_bare_percent_in_base_is_a_warning(self):
        """save17: Base 'Save 16%' loses its '%' sign through String(format:)."""
        self.base({"save17": "Save 16%"})
        found = rules_of(run_linter(self.root), "unescaped-percent")
        self.assertEqual([(f.lang, f.severity) for f in found], [("Base", "warning")])

    def test_legacy_placeholder_in_base_is_not_reported(self):
        self.base({"%1 of %2": "%1 of %2"})
        self.assertEqual(run_linter(self.root), [])

    def test_space_flag_in_a_legacy_key_is_not_reported(self):
        self.base({"Your payment for the %1 plan": "Your payment for the %1 plan"})
        self.assertEqual(run_linter(self.root), [])


class TestFoundationFormatModel(LinterTestCase):
    def test_flags_after_the_width_form_a_conversion(self):
        """tr save17 '%16 tasarruf et': Foundation reads '%16 ta' as one conversion."""
        sig = L.format_signature("%16 tasarruf et")
        self.assertEqual(sig.slots, {1: "a"})
        self.assertEqual(sig.bare, 0)

    def test_star_width_and_precision_take_their_own_slots(self):
        self.assertEqual(L.format_signature("%*d|").slots, {1: "*", 2: "d"})
        self.assertEqual(L.format_signature("%.*f").slots, {1: "*", 2: "f"})

    def test_wide_length_modifier_is_recorded(self):
        self.assertEqual(L.format_signature("%lld and %d").wide, {1})

    def test_translation_that_consumes_an_argument_is_an_error(self):
        self.base({"save17": "Save 16%%"})
        self.lang("tr", {"save17": "%16 tasarruf et"})
        found = rules_of(run_linter(self.root), "format-arity")
        self.assertEqual([f.lang for f in found], ["tr"])

    def test_dropped_64_bit_modifier_is_an_error(self):
        self.base({"size": "%lld bytes"})
        self.lang("de", {"size": "%d Bytes"})
        found = rules_of(run_linter(self.root), "format-type")
        self.assertEqual(len(found), 1)
        self.assertIn("64-bit", found[0].message)

    def test_star_width_in_a_translation_is_an_extra_slot(self):
        self.base({"n": "%d items"})
        self.lang("de", {"n": "%*d Artikel"})
        self.assertEqual(len(rules_of(run_linter(self.root), "format-arity")), 1)

    def test_legacy_key_keeps_its_raw_placeholders(self):
        """'%1 de %2' is replaced by the app, not by printf, so '%1 d' is no conversion."""
        self.base({"%1 of %2": "%1 of %2"})
        self.lang("pt", {"%1 of %2": "%1 de %2"})
        self.lang("nl", {"%1 of %2": "%1 van %2."})
        self.assertEqual(run_linter(self.root), [])

    def test_legacy_key_that_drops_a_raw_placeholder_is_an_error(self):
        self.base({"%1 of %2": "%1 of %2"})
        self.lang("pt", {"%1 of %2": "%1 de"})
        found = rules_of(run_linter(self.root), "format-arity")
        self.assertEqual(len(found), 1)
        self.assertIn("%2", found[0].message)


class TestGluedPercentForms(LinterTestCase):
    def test_percent_and_space_before_a_token_is_glued(self):
        self.assertEqual(L.percent_glued_tokens("Save 50% [A]now[/A]"), ["[A]"])

    def test_glued_percent_in_base_with_a_space_is_reported(self):
        self.base({"k1": "Save 50% [A]now[/A]"})
        found = rules_of(run_linter(self.root), "percent-glued-to-token")
        self.assertEqual([(f.lang, f.severity) for f in found], [("Base", "warning")])


class TestValueChecks(LinterTestCase):
    def test_unknown_markup_token_is_a_warning(self):
        """fr showLastSeen '«[w]Vu pour la dernière fois[w]»': '[w]' shows as text."""
        self.base({"seen": "Show last seen", "link": "[A]Open[/A]"})
        self.lang("fr", {"seen": "Afficher «[w]Vu[w]»", "link": "[A]Ouvrir[/A] [A]"})
        found = rules_of(run_linter(self.root), "unknown-markup-token")
        self.assertEqual([(f.key, f.severity) for f in found], [("seen", "warning")])

    def test_trailing_newline_that_base_lacks_is_a_warning(self):
        """ja readOnly '読み取り専用\\n' for Base 'Read-only'."""
        self.base({"readOnly": "Read-only"})
        self.lang("ja", {"readOnly": "読み取り専用\n"})
        found = rules_of(run_linter(self.root), "newline-differs")
        self.assertEqual([(f.lang, f.severity) for f in found], [("ja", "warning")])

    def test_en_must_match_base(self):
        self.base({"a": "New text"})
        self.lang("en", {"a": "Old text"})
        found = rules_of(run_linter(self.root), "en-differs-from-base")
        self.assertEqual([f.severity for f in found], ["warning"])


# ======================================================================================
# Plural variants compared with Base
# ======================================================================================

def plural_two(var_a, var_b, fmt):
    """An entry whose variable `a` may reference variable `b` from inside a variant."""
    def sub(variants):
        out = {"NSStringFormatSpecTypeKey": "NSStringPluralRuleType",
               "NSStringFormatValueTypeKey": "d"}
        out.update(variants)
        return out
    return {"NSStringLocalizedFormatKey": fmt, "a": sub(var_a), "b": sub(var_b)}


class TestPluralComparedWithBase(LinterTestCase):
    def test_variant_with_wrong_type_or_extra_slot_is_an_error(self):
        self.base(sdict={"files": plural_entry({"one": "%d file", "other": "%d files"})})
        self.lang("de", sdict={"files": plural_entry({"one": "%d Datei %@",
                                                      "other": "%@ Dateien"})})
        found = run_linter(self.root)
        self.assertEqual(len(rules_of(found, "format-arity")), 1)
        self.assertEqual(len(rules_of(found, "format-type")), 1)

    def test_extra_slot_in_the_format_key_is_an_error(self):
        self.base(sdict={"files": plural_entry({"one": "%d file", "other": "%d files"})})
        entry = plural_entry({"one": "%d Datei", "other": "%d Dateien"})
        entry["NSStringLocalizedFormatKey"] = "%#@count@ in %@"
        self.lang("de", sdict={"files": entry})
        found = rules_of(run_linter(self.root), "format-arity")
        self.assertEqual(len(found), 1)
        self.assertIn("format key", found[0].message)

    def test_one_form_may_add_or_drop_the_count(self):
        self.base(sdict={"files": plural_entry({"one": "a file", "other": "%d files"})})
        self.lang("de", sdict={"files": plural_entry({"one": "%d Datei", "other": "Dateien"})})
        self.assertEqual(run_linter(self.root), [])

    def test_value_type_that_differs_from_base_is_an_error(self):
        self.base(sdict={"files": plural_entry({"one": "%d file", "other": "%d files"})})
        self.lang("de", sdict={"files": plural_entry({"one": "%d Datei", "other": "%d Dateien"},
                                                     value_type="u")})
        self.assertEqual(len(rules_of(run_linter(self.root), "format-type")), 1)

    def test_variant_that_drops_a_markup_token_is_an_error(self):
        """nl notification.transfer.download.subtitle other='%d voltooid' drops '[A]'."""
        self.base(sdict={"sub": plural_entry({"one": "%d of [A] completed",
                                              "other": "%d of [A] completed"})})
        self.lang("nl", sdict={"sub": plural_entry({"one": "%d van [A] voltooid",
                                                    "other": "%d voltooid"})})
        found = rules_of(run_linter(self.root), "missing-markup-token")
        self.assertEqual(len(found), 1)
        self.assertIn("count.other", found[0].message)

    def test_positional_reference_is_followed(self):
        """'%1$#@n@' is a valid reference. de with only 'one' renders (null) for 2."""
        entry = plural_entry({"one": "%d file", "other": "%d files"}, var="n")
        entry["NSStringLocalizedFormatKey"] = "%1$#@n@"
        self.base(sdict={"pos": entry})
        de = plural_entry({"one": "%d Datei"}, var="n")
        de["NSStringLocalizedFormatKey"] = "%1$#@n@"
        self.lang("de", sdict={"pos": de})
        found = run_linter(self.root)
        self.assertEqual(rules_of(found, "plural-unused-variant"), [])
        self.assertEqual([f.lang for f in rules_of(found, "plural-renders-null")], ["de"])

    def test_variable_referenced_from_a_variant_is_used_and_checked(self):
        base = plural_two({"one": "%#@b@ in 1 folder", "other": "%#@b@ in %d folders"},
                          {"one": "%d file", "other": "%d files"}, "%#@a@")
        self.base(sdict={"nest": base})
        de = plural_two({"one": "%#@b@ in 1 Ordner", "other": "%#@b@ in %d Ordnern"},
                        {}, "%#@a@")
        self.lang("de", sdict={"nest": de})
        found = run_linter(self.root)
        self.assertEqual(rules_of(found, "plural-unused-variant"), [])
        nulls = rules_of(found, "plural-renders-null")
        self.assertEqual([(f.lang, "b:" in f.message) for f in nulls], [("de", True)])

    def test_two_variables_get_two_fingerprints(self):
        base = plural_two({"one": "x", "other": "y"}, {"one": "f", "other": "g"},
                          "%#@a@ %#@b@")
        self.base(sdict={"k": base})
        self.lang("ru", sdict={"k": plural_two({}, {}, "%#@a@ %#@b@")})
        nulls = rules_of(run_linter(self.root), "plural-renders-null")
        self.assertEqual(len(nulls), 2)
        self.assertNotEqual(nulls[0].fingerprint, nulls[1].fingerprint)


# ======================================================================================
# .strings scanner, parse failures, paths
# ======================================================================================

class TestStringsScanner(LinterTestCase):
    def test_scanner_skips_comments_and_reads_every_pair(self):
        text = ('﻿"a" = "1";\n"a" = "2";\n/*\n"b" = "x";\n*/\n"b" = "y";\n'
                '"c" = "1"; "c" = "2";\nd = "1";\nd = "2";\n')
        self.assertEqual(L.raw_key_order(text), ["a", "a", "b", "c", "c", "d", "d"])

    def test_scanner_reports_line_numbers_and_unescapes_keys(self):
        text = '// note\n"a" = "1";\n\n"say \\"hi\\"" = "2";\n'
        self.assertEqual(L.scan_strings_keys(text), [("a", 2), ('say "hi"', 4)])

    def test_duplicates_follow_plutil(self):
        self.base({"a": "A"})
        d = os.path.join(self.root, "de.lproj")
        os.makedirs(d, exist_ok=True)
        with open(os.path.join(d, "Localizable.strings"), "w", encoding="utf-8") as fh:
            fh.write('﻿"a" = "1";\n"a" = "2";\n/* "b" = "x"; */\n"b" = "y";\n'
                     '"c" = "1"; "c" = "2";\nd = "1";\nd = "2";\n')
        write_stringsdict(self.root, "de", {})
        found = rules_of(run_linter(self.root), "duplicate-key")
        self.assertEqual(sorted(f.key for f in found), ["a", "c", "d"])

    def test_stringsdict_key_lines(self):
        text = ("<plist>\n<dict>\n\t<key>first</key>\n\t<dict>\n\t\t<key>inner</key>\n"
                "\t</dict>\n\t<key>a &amp; b</key>\n\t<dict/>\n</dict>\n</plist>\n")
        self.assertEqual(L.stringsdict_key_lines(text), {"first": 3, "a & b": 7})


class TestParseFailureScope(LinterTestCase):
    def broken_de(self):
        self.base({"a": "A", "b": "B"})
        d = os.path.join(self.root, "de.lproj")
        os.makedirs(d, exist_ok=True)
        with open(os.path.join(d, "Localizable.strings"), "w", encoding="utf-8") as fh:
            fh.write('"a" = "unterminated;\n')
        write_stringsdict(self.root, "de", {})

    def test_broken_file_does_not_flood_missing_keys(self):
        self.broken_de()
        found = run_linter(self.root)
        self.assertEqual([f.rule for f in found], ["parse-error"])

    def test_parse_error_exits_2(self):
        self.broken_de()
        self.assertEqual(L.main(["--root", self.root, "--format", "json", "--output",
                                 os.path.join(self.root, "r.json")]), 2)

    def test_base_parse_error_has_a_path(self):
        os.makedirs(os.path.join(self.root, "Base.lproj"))
        with open(os.path.join(self.root, "Base.lproj", "Localizable.strings"), "w") as fh:
            fh.write('"a" = ;\n')
        found = run_linter(self.root)
        self.assertTrue(found[0].path.endswith("Base.lproj/Localizable.strings"))

    def test_missing_explicit_root_next_to_a_valid_one_exits_2(self):
        self.base({"a": "A"})
        self.assertEqual(L.main(["--root", self.root,
                                 "--root", os.path.join(self.root, "nope")]), 2)


class TestReportPaths(LinterTestCase):
    def test_paths_use_the_label_and_carry_line_numbers(self):
        self.base({"x": "X", "added": "Added to %@"})
        self.lang("pt", {"x": "X", "added": "Adicionada a %s"})
        found = L.Linter(self.root, label="Res").run()
        self.assertEqual(found[0].path, os.path.join("Res", "pt.lproj", "Localizable.strings"))
        self.assertEqual(found[0].line, 2)
        row = json.loads(L.render_gitlab(found))[0]
        self.assertEqual(row["location"], {"path": found[0].path, "lines": {"begin": 2}})

    def test_display_root_is_relative_inside_the_repository(self):
        inside = os.path.join(L.repo_root(), "Modules", "X")
        self.assertEqual(L.display_root(inside), os.path.join("Modules", "X"))
        self.assertEqual(L.display_root(self.root), os.path.abspath(self.root))


class TestBaselineCatchesValueChange(LinterTestCase):
    def test_new_problem_on_a_known_key_is_not_hidden(self):
        self.base({"k": "%@ and %@"})
        self.lang("ru", {"k": "%@"})
        baseline = os.path.join(self.root, "baseline.json")
        self.assertEqual(L.main(["--root", self.root, "--baseline", baseline,
                                 "--write-baseline"]), 0)
        self.lang("ru", {"k": "%@ %@ %@ %@"})
        self.assertEqual(L.main(["--root", self.root, "--baseline", baseline,
                                 "--format", "json", "--output",
                                 os.path.join(self.root, "r.json")]), 1)


# ======================================================================================
# Changes-only mode (git repositories made in a temp dir)
# ======================================================================================

RES = "Res"


class GitRepoTestCase(unittest.TestCase):
    """A small repository with a resources folder at Res/."""

    def setUp(self):
        self.repo = tempfile.mkdtemp(prefix="l10n_git_")
        self.addCleanup(shutil.rmtree, self.repo, True)
        self.res = os.path.join(self.repo, RES)
        os.makedirs(self.res)
        config = os.path.join(self.repo, ".gitconfig-test")
        open(config, "w").close()
        # Keep the user's git config (signing, hooks) out of the test repository.
        self.env = dict(os.environ, GIT_CONFIG_GLOBAL=config, GIT_CONFIG_NOSYSTEM="1",
                        GIT_AUTHOR_NAME="t", GIT_AUTHOR_EMAIL="t@example.com",
                        GIT_COMMITTER_NAME="t", GIT_COMMITTER_EMAIL="t@example.com")
        self.git("init", "-q")

    def git(self, *args):
        subprocess.run(["git", *args], cwd=self.repo, env=self.env, check=True,
                       capture_output=True)

    def commit(self, message):
        self.git("add", "-A")
        self.git("commit", "-q", "-m", message)

    def lint(self, *args):
        old = dict(os.environ)
        os.environ.update(self.env)
        try:
            return L.main(["--root", self.res, "--changed-since", "base", *args])
        finally:
            os.environ.clear()
            os.environ.update(old)

    def start(self, base_strings, de_strings, base_sdict=None, de_sdict=None):
        write_strings(self.res, "Base", base_strings)
        write_stringsdict(self.res, "Base", base_sdict or {})
        write_strings(self.res, "de", de_strings)
        write_stringsdict(self.res, "de", de_sdict or {})
        self.commit("base")
        self.git("tag", "base")
        self.git("checkout", "-q", "-b", "feature")

    def read(self, name):
        with open(os.path.join(self.repo, name), encoding="utf-8") as fh:
            return fh.read()


class TestChangedKeys(GitRepoTestCase):
    def test_changed_strings_keys_are_new_or_edited(self):
        self.start({"a": "A", "b": "B", "c": "C"}, {"a": "A", "b": "B", "c": "C"})
        write_strings(self.res, "de", {"a": "A2", "b": "B", "c": "C", "d": "D"})
        self.commit("edit")
        change = L.detect_changes(self.res, "base")
        self.assertEqual(change.keys, {"a", "d"})
        self.assertEqual(change.files, [os.path.join("de.lproj", "Localizable.strings")])
        self.assertEqual(change.langs, ["de"])
        self.assertEqual(change.new_base_keys, set())
        shutil.rmtree(change.tmp_dir)

    def test_stringsdict_key_changes_when_a_variant_changes(self):
        sd = {"f": plural_entry({"one": "%d file", "other": "%d files"}),
              "g": plural_entry({"one": "%d day", "other": "%d days"})}
        self.start({}, {}, base_sdict=sd, de_sdict=sd)
        write_stringsdict(self.res, "Base", dict(sd, g=plural_entry({"one": "%d day",
                                                                     "other": "%d dayz"})))
        self.commit("edit")
        change = L.detect_changes(self.res, "base")
        self.assertEqual(change.keys, {"g"})
        shutil.rmtree(change.tmp_dir)

    def test_new_base_key_is_listed(self):
        self.start({"a": "A"}, {"a": "A"})
        write_strings(self.res, "Base", {"a": "A", "n": "New"})
        self.commit("add")
        change = L.detect_changes(self.res, "base")
        self.assertEqual(change.keys, {"n"})
        self.assertEqual(change.new_base_keys, {"n"})
        shutil.rmtree(change.tmp_dir)

    def test_added_duplicate_with_the_same_value_is_a_change(self):
        self.start({"a": "A"}, {"a": "A"})
        with open(os.path.join(self.res, "de.lproj", "Localizable.strings"), "a") as fh:
            fh.write('"a" = "A";\n')
        self.commit("dup")
        change = L.detect_changes(self.res, "base")
        self.assertEqual(change.keys, {"a"})
        shutil.rmtree(change.tmp_dir)

    def test_other_files_are_not_a_change(self):
        self.start({"a": "A"}, {"a": "A"})
        with open(os.path.join(self.repo, "README"), "w") as fh:
            fh.write("x")
        self.commit("readme")
        self.assertIsNone(L.detect_changes(self.res, "base"))


class TestChangedSinceCLI(GitRepoTestCase):
    def test_only_problems_on_changed_keys_are_reported(self):
        self.start({"a": "%@", "b": "%@"}, {"a": "%@", "b": "%@"})
        write_strings(self.res, "de", {"a": "%s", "b": "%@"})
        self.commit("break a")
        out = os.path.join(self.repo, "r.json")
        self.assertEqual(self.lint("--format", "json", "--output", out), 1)
        rows = json.loads(self.read("r.json"))
        self.assertEqual([(r["rule"], r["key"]) for r in rows], [("format-type", "a")])

    def test_problem_already_at_the_merge_base_is_known(self):
        self.start({"a": "%@"}, {"a": "%s"})
        write_strings(self.res, "Base", {"a": "%@", "z": "Z"})
        write_strings(self.res, "de", {"a": "%s", "z": "Z"})
        self.commit("touch")
        with open(os.path.join(self.res, "de.lproj", "Localizable.strings"), "a") as fh:
            fh.write('"a" = "%s";\n')  # same value, declared twice: key `a` changed
        self.commit("dup")
        self.assertEqual(self.lint("--format", "mr-markdown", "--output",
                                   os.path.join(self.repo, "r.md")), 0)
        md = self.read("r.md")
        self.assertIn("Already on base (1, not counted)", md)
        self.assertIn("Localization check: 1 warning", md)

    def test_new_base_key_waits_for_translation(self):
        self.start({"a": "A"}, {"a": "A"})
        write_strings(self.res, "Base", {"a": "A", "n": "New", "m": "More"})
        self.commit("add keys")
        out = os.path.join(self.repo, "r.md")
        self.assertEqual(self.lint("--format", "mr-markdown", "--output", out,
                                   "--min-severity", "warning"), 0)
        md = self.read("r.md")
        self.assertTrue(md.startswith("<!-- l10n-lint -->\n#### :white_check_mark: "))
        self.assertIn("2 changed keys in Base. No new problems.", md)
        self.assertIn("2 new keys wait for translation in 1 language.", md)

    def test_no_change_writes_the_no_changes_comment(self):
        self.start({"a": "A"}, {"a": "A"})
        out = os.path.join(self.repo, "r.md")
        self.assertEqual(self.lint("--format", "mr-markdown", "--output", out), 0)
        self.assertIn("No Localizable changes in this MR any more.", self.read("r.md"))

    def test_mr_markdown_needs_changed_since(self):
        write_strings(self.res, "Base", {"a": "A"})
        self.assertEqual(L.main(["--root", self.res, "--format", "mr-markdown"]), 2)


# ======================================================================================
# MR comment layout
# ======================================================================================

INFO = {"commit": "a1b2c3d", "base_name": "develop", "changed_keys": 14,
        "changed_langs": ["Base", "en"], "lang_count": 20,
        "report_url": "https://ci/artifact/outputs/l10n_lint.json"}


def finding(sev, rule, lang, key, short, value=None, base_value=None):
    return L.Finding(sev, rule, lang, key, short, short=short, value=value,
                     base_value=base_value)


class TestMrMarkdown(unittest.TestCase):
    def test_clean_run(self):
        md = L.render_mr_markdown([], [], [], dict(INFO, changed_keys=12))
        self.assertEqual(md, "<!-- l10n-lint -->\n"
                             "#### :white_check_mark: Localization check\n"
                             "12 changed keys in Base, en. No new problems.\n"
                             "<sub>Commit `a1b2c3d` · [full report]"
                             "(https://ci/artifact/outputs/l10n_lint.json)</sub>\n")

    def test_rows_merge_languages_and_list_values(self):
        new = [finding("error", "missing-markup-token", lang, "sub", "Plural `other` drops `[A]`.")
               for lang in ("nl", "id", "ja")]
        new.append(finding("error", "format-type", "pt", "added",
                           "`%s` where Base has `%@`.", "Adicionada a %s", "Added to %@"))
        new.append(finding("warning", "unescaped-percent", "fr", "pct", "Unescaped `%`."))
        known = [finding("error", "format-arity", "ar", "twoMonthsFree", "Drops `%1`")]
        md = L.render_mr_markdown(new, known, [], INFO)
        lines = md.splitlines()
        self.assertEqual(lines[0], "<!-- l10n-lint -->")
        self.assertEqual(lines[1], "#### :x: Localization check: 4 errors, 1 warning")
        self.assertIn("| `sub` | id, ja, nl | **error** Plural `other` drops `[A]`. |", lines)
        self.assertIn("| `pct` | fr | warning Unescaped `%`. |", lines)
        self.assertIn("<details open><summary>Values (1)</summary>", lines)
        self.assertIn("  - Base: `Added to %@`", lines)
        self.assertIn("<details open><summary>Already on develop (1, not counted)</summary>", lines)
        self.assertIn("| `twoMonthsFree` | ar | error Drops `%1` |", lines)
        self.assertIn("Showing 3 of 3 rows.", lines)
        self.assertTrue(lines[-1].startswith("<sub>Commit `a1b2c3d` · Report only"))

    def test_rows_are_capped(self):
        new = [finding("warning", "missing-key", "en", f"k{i:02}", "Missing.") for i in range(25)]
        md = L.render_mr_markdown(new, [], [], INFO)
        self.assertIn("Showing 20 of 25 rows. See the full report.", md)
        self.assertNotIn("`k20`", md)

    def test_code_spans_escape_pipes_and_backticks(self):
        self.assertEqual(L.md_code("a|b", in_table=True), "`a\\|b`")
        self.assertEqual(L.md_code("use `x`"), "`` use `x` ``")
        self.assertEqual(L.md_code("x" * 90), "`" + "x" * 80 + "…`")
        self.assertEqual(L.md_code("<b>1\n2</b>"), "`<b>1\\n2</b>`")

    def test_many_languages_are_shortened(self):
        langs = ["ar", "es", "fr", "it", "ja", "ko", "pt", "ro"]
        self.assertEqual(L._lang_list(langs), "ar, es, fr, it, ja, ko … (8)")

    def test_no_changes_comment(self):
        self.assertEqual(L.render_mr_no_changes({"commit": "a1b2c3d"}),
                         "<!-- l10n-lint -->\n#### Localization check\n"
                         "No Localizable changes in this MR any more. Commit `a1b2c3d`.\n")


# ======================================================================================
# Integration smoke test against the real repository
# ======================================================================================

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REAL_ROOT = os.path.join(
    REPO_ROOT, "Modules/Presentation/MEGAL10n/Framework/MEGAL10n/MEGAL10n/Resources")


@unittest.skipUnless(os.path.isdir(REAL_ROOT), "MEGAL10n resources not present")
class TestAgainstRealResources(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.findings = run_linter(REAL_ROOT)

    def test_every_file_parses(self):
        self.assertEqual(rules_of(self.findings, "parse-error"), [])

    def test_all_expected_languages_are_scanned(self):
        langs = set(L.Linter(REAL_ROOT).languages())
        self.assertTrue({"Base", "en", "de", "ru", "pl", "zh-Hant"} <= langs)

    def test_ordinary_plural_keys_are_not_flagged_for_pl_and_ru(self):
        """Guards the pl/ru `other` false positive from ever coming back."""
        noisy = [
            f for f in errors(self.findings)
            if f.lang in ("pl", "ru") and f.key in (
                "general.format.count.file", "general.format.count.folder",
                "call.duration.minute", "nameCollision.applyToAll")
        ]
        self.assertEqual(noisy, [], f"false positives resurfaced: {noisy}")

    def test_runs_within_a_sane_time_budget(self):
        """The tool it replaces took hours; this must stay usable as a merge gate."""
        import time
        start = time.time()
        run_linter(REAL_ROOT)
        self.assertLess(time.time() - start, 60)


if __name__ == "__main__":
    unittest.main(verbosity=2)
