#!/usr/bin/env python3
import json
from pathlib import Path

skill_dir = Path(__file__).resolve().parent.parent
template = Path(r"C:\Users\SeanS\.agents\skills\skill-creator\assets\eval_review.html").read_text(encoding="utf-8")
eval_data = json.loads((skill_dir / "evals" / "eval_set_trigger.json").read_text(encoding="utf-8"))
text = (skill_dir / "SKILL.md").read_text(encoding="utf-8")
desc_lines = []
in_desc = False
for line in text.splitlines():
    if line.strip() == "description: |":
        in_desc = True
        continue
    if in_desc:
        if line.startswith("metadata:"):
            break
        desc_lines.append(line.strip())
desc = " ".join(desc_lines)

html = template.replace("__EVAL_DATA_PLACEHOLDER__", json.dumps(eval_data, ensure_ascii=False))
html = html.replace("__SKILL_NAME_PLACEHOLDER__", "n64-decomp")
html = html.replace("__SKILL_DESCRIPTION_PLACEHOLDER__", desc)
(skill_dir / "evals" / "description_review.html").write_text(html, encoding="utf-8")
print(skill_dir / "evals" / "description_review.html")
