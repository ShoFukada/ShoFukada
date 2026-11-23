#!/usr/bin/env bash
# プロフィールの README に出すカード（SVG）を各サービスから取り、出力先のフォルダに置く。
# 取れなかったカードは前回の SVG を残し、最後に失敗で終わる（README は前回の絵を出し続ける）。
# 使い方: scripts/update-cards.sh <出力先のフォルダ>
set -uo pipefail

out=${1:?出力先のフォルダを渡す}
mkdir -p "$out"
failed=()

# 名前・成功したカードにだけ出る文字列・URL
# どのサービスもエラーのときに 200 でエラーの SVG を返すため、ステータスではなく中身で成否を見る。
cards=(
  "header|<svg|https://capsule-render.vercel.app/api?type=waving&color=0:0f2027,50:203a43,100:2c5364&height=200&section=header&text=Sho%20Fukada&fontSize=48&fontColor=e0e6ed&animation=fadeIn&desc=CTO%20%40%20Medurance%20%2F%20Full-Stack%20Engineer&descSize=18&descAlignY=75"
  "typing|<svg|https://readme-typing-svg.demolab.com/?font=Fira+Code&size=17&pause=1200&color=70A5FD&center=true&vCenter=true&width=620&lines=Information+Retrieval+%C2%B7+RAG+%C2%B7+AI+Agents;Computer+Vision+%C2%B7+Cloud+Architecture;Web+%C2%B7+Mobile+%C2%B7+Infrastructure%2C+end+to+end"
  "stats|Total Commits|https://github-readme-stats-five-nu-21.vercel.app/api?username=ShoFukada&show_icons=true&theme=tokyonight&hide_border=true&hide_rank=true"
  "top-langs|Most Used Languages|https://github-readme-stats-five-nu-21.vercel.app/api/top-langs/?username=ShoFukada&exclude_repo=rag_test,github-readme-stats,github-readme-streak-stats&layout=compact&theme=tokyonight&hide_border=true&langs_count=8"
  "streak|Current Streak|https://github-readme-streak-stats-sand-seven.vercel.app/?user=ShoFukada&theme=tokyonight&hide_border=true"
  "activity|Contribution Graph|https://github-readme-activity-graph.vercel.app/graph?username=ShoFukada&theme=tokyo-night&hide_border=true&area=true"
  "footer|<svg|https://capsule-render.vercel.app/api?type=waving&color=0:2c5364,50:203a43,100:0f2027&height=100&section=footer"
)

for card in "${cards[@]}"; do
  IFS='|' read -r name marker url <<<"$card"
  tmp="$out/.$name.tmp"
  ok=
  for attempt in 1 2 3; do
    if curl -fsS --max-time 60 -o "$tmp" "$url" && grep -q '<svg' "$tmp" && grep -qF "$marker" "$tmp"; then
      ok=1
      break
    fi
    [ "$attempt" -lt 3 ] && sleep "${RETRY_WAIT:-15}"
  done
  if [ -n "$ok" ]; then
    mv "$tmp" "$out/$name.svg"
    echo "ok: $name"
  else
    rm -f "$tmp"
    echo "::warning::$name を取れなかったので前回の SVG を残す"
    failed+=("$name")
  fi
done

if [ ${#failed[@]} -gt 0 ]; then
  echo "::error::取れなかったカード: ${failed[*]}"
  exit 1
fi
