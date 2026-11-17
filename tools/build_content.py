#!/usr/bin/env python3
"""Builds the app's JSON content files from the Python sources in this folder.

Usage:  python3 tools/build_content.py
Output: Talaqa/Resources/Content/*.json
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

from content_vocab import VOCAB          # noqa: E402
from content_vocab_extra import VOCAB_EXTRA  # noqa: E402
from content_grammar import LESSONS      # noqa: E402
from content_other import PLACEMENT, SCENARIOS, STORIES, SHADOWING  # noqa: E402

OUT = os.path.join(HERE, "..", "Talaqa", "Resources", "Content")
LEVELS = ["A1", "A2", "B1", "B2", "C1", "C2"]


def slug(text):
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


def exercise(prefix, i, ex):
    kind = ex[0]
    if kind == "mc":
        _, prompt, prompt_ar, options, answer, expl = ex
        assert answer in options, f"{prefix}: answer {answer!r} not in options"
        return {"id": f"{prefix}-{i}", "kind": "multipleChoice", "prompt": prompt,
                "promptAr": prompt_ar, "options": options, "answer": answer, "explanationAr": expl}
    if kind == "fill":
        _, prompt, prompt_ar, answer, expl = ex
        return {"id": f"{prefix}-{i}", "kind": "fillBlank", "prompt": prompt,
                "promptAr": prompt_ar, "options": None, "answer": answer, "explanationAr": expl}
    if kind == "order":
        _, prompt_ar, answer, expl = ex
        return {"id": f"{prefix}-{i}", "kind": "reorder", "prompt": "Put the words in the correct order.",
                "promptAr": prompt_ar, "options": None, "answer": answer, "explanationAr": expl}
    raise ValueError(kind)


def build():
    vocab, seen = [], set()
    merged = {lvl: VOCAB.get(lvl, []) + VOCAB_EXTRA.get(lvl, []) for lvl in LEVELS}
    for level, items in merged.items():
        assert level in LEVELS
        for word, ipa, pos, ar, ex, ex_ar, topic in items:
            wid = f"{level.lower()}-{slug(word)}"
            assert wid not in seen, wid
            seen.add(wid)
            vocab.append({"id": wid, "word": word, "ipa": ipa, "pos": pos, "meaningAr": ar,
                          "example": ex, "exampleAr": ex_ar, "topic": topic, "level": level})

    lessons = []
    for l in LESSONS:
        lessons.append({
            "id": l["id"], "title": l["title"], "titleAr": l["titleAr"], "level": l["level"],
            "summaryAr": l["summaryAr"],
            "sections": [{"headingAr": h, "bodyAr": b, "examples": e} for h, b, e in l["sections"]],
            "arabicTip": l.get("tip"),
            "exercises": [exercise(l["id"], i, ex) for i, ex in enumerate(l["ex"])],
        })

    placement = [{"id": f"p{i}", "level": lvl, "prompt": p, "options": o, "answer": a}
                 for i, (lvl, p, o, a) in enumerate(PLACEMENT)]
    for q in placement:
        assert 0 <= q["answer"] < len(q["options"])

    stories = []
    for s in STORIES:
        stories.append({
            "id": s["id"], "title": s["title"], "titleAr": s["titleAr"], "level": s["level"],
            "paragraphs": s["paragraphs"], "glossary": s["glossary"],
            "questions": [exercise(s["id"], i, q) for i, q in enumerate(s["questions"])],
        })

    shadowing = []
    for focus, focus_ar, tip, level, sentences in SHADOWING:
        for i, text in enumerate(sentences):
            shadowing.append({"id": f"{slug(focus)}-{i}", "text": text, "focus": focus,
                              "focusAr": focus_ar, "tipAr": tip, "level": level})

    os.makedirs(OUT, exist_ok=True)
    files = {"vocabulary": vocab, "grammar": lessons, "placement": placement,
             "scenarios": SCENARIOS, "stories": stories, "shadowing": shadowing}
    for name, data in files.items():
        with open(os.path.join(OUT, f"{name}.json"), "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=1)
        print(f"{name}.json: {len(data)} items")


if __name__ == "__main__":
    build()
