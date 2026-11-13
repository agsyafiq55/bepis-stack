#!/bin/bash
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // .model.id // "unknown"')
pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
pct=${pct:-0}
in_tok=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
out_tok=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

# 10-cell meter
filled=$(( pct / 10 ))
[ "$filled" -gt 10 ] && filled=10
bar=""
for i in $(seq 1 10); do
  if [ "$i" -le "$filled" ]; then bar+="█"; else bar+="░"; fi
done

# Color: green < 60%, yellow < 85%, red otherwise
if [ "$pct" -lt 60 ]; then color='\033[32m'
elif [ "$pct" -lt 85 ]; then color='\033[33m'
else color='\033[31m'
fi
reset='\033[0m'

printf "\033[36m[%s]\033[0m %s | ${color}ctx %s %d%%${reset} | tokens in:%s out:%s | \$%.2f" \
  "$model" "$(basename "$PWD")" "$bar" "$pct" "$in_tok" "$out_tok" "$cost"
