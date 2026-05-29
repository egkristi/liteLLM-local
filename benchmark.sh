#!/usr/bin/env bash
# ===========================================================================
# benchmark.sh — LiteLLM Local Model Benchmark
# ===========================================================================
# Sends a standard set of coding prompts to each model and reports latency
# and estimated cost. Results are saved to logs/benchmark-*.csv and printed
# as a formatted table.
#
# Usage:
#   ./benchmark.sh                          # Benchmark all cloud models
#   ./benchmark.sh --models deepseek-v4-pro,groq-llama  # Specific models
#   ./benchmark.sh --prompts 3              # Use 3 prompts per model
#   ./benchmark.sh --local                  # Include local Ollama models
#   ./benchmark.sh --all                    # Benchmark every model in config
#   ./benchmark.sh --output results.csv     # Save to custom file
#   ./benchmark.sh --json                   # Output JSON (for tooling)
# ===========================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
PORT="${PORT:-4000}"
PROMPTS_COUNT=3
INCLUDE_LOCAL=false
INCLUDE_ALL=false
OUTPUT_FILE=""
JSON_OUTPUT=false
MODEL_FILTER=""

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --models) MODEL_FILTER="$2"; shift 2 ;;
    --prompts) PROMPTS_COUNT="$2"; shift 2 ;;
    --local) INCLUDE_LOCAL=true; shift ;;
    --all) INCLUDE_ALL=true; shift ;;
    --output) OUTPUT_FILE="$2"; shift 2 ;;
    --json) JSON_OUTPUT=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

mkdir -p "$LOG_DIR"

# --- Standard benchmark prompts ---
BENCHMARK_PROMPTS=(
  "Write a Python function to merge two sorted lists into one sorted list. Include type hints and a docstring."
  "Explain the difference between TCP and UDP in networking. Give a practical example of when to use each."
  "Write a bash script that monitors a directory for new files and prints a notification when one appears."
  "Refactor this code to be more Pythonic: for i in range(len(items)): print(items[i])"
  "What is the time complexity of quicksort? Explain the best, average, and worst cases."
  "Write a SQL query to find the top 5 most common words in a 'comments' table."
  "Create a simple React component that shows a counter with increment/decrement buttons."
  "Explain how garbage collection works in Python. What is reference counting?"
  "Write a Dockerfile for a Python Flask app that uses poetry for dependency management."
  "What is the CAP theorem? Explain with examples from distributed databases."
)

# --- Pricing per million tokens (input / output) ---
# Sources: provider pricing pages, approximate as of May 2026
declare -A MODEL_PRICING
MODEL_PRICING["deepseek-v4-pro"]="0.14 0.28"
MODEL_PRICING["claude-sonnet"]="3.00 15.00"
MODEL_PRICING["claude-opus"]="15.00 75.00"
MODEL_PRICING["groq-llama"]="0 0"  # free tier
MODEL_PRICING["mistral-large"]="2.00 6.00"
MODEL_PRICING["codestral"]="1.00 3.00"
MODEL_PRICING["kimi-latest"]="0.08 0.28"
MODEL_PRICING["deepseek-local"]="0 0"
MODEL_PRICING["qwen2.5-coder"]="0 0"
MODEL_PRICING["deepseek-v4-pro-cloud"]="0 0"
MODEL_PRICING["deepseek-v4-flash-cloud"]="0 0"
MODEL_PRICING["gemma4-31b-cloud"]="0 0"
MODEL_PRICING["gemini-3-flash-cloud"]="0 0"
MODEL_PRICING["glm-5.1-cloud"]="0 0"
MODEL_PRICING["kimi-k2.5-cloud"]="0 0"
MODEL_PRICING["kimi-k2.6-cloud"]="0 0"
MODEL_PRICING["minimax-m2.7-cloud"]="0 0"
MODEL_PRICING["ministral-3-3b-cloud"]="0 0"
MODEL_PRICING["ministral-3-8b-cloud"]="0 0"
MODEL_PRICING["ministral-3-14b-cloud"]="0 0"
MODEL_PRICING["mistral-large-3-675b-cloud"]="0 0"
MODEL_PRICING["qwen3.5-397b-cloud"]="0 0"
MODEL_PRICING["qwen3-vl-235b-cloud"]="0 0"
MODEL_PRICING["qwen3-vl-235b-instruct-cloud"]="0 0"
MODEL_PRICING["nomic-embed-text"]="0 0"

# --- Determine which models to benchmark ---
get_models() {
  if [ -n "$MODEL_FILTER" ]; then
    # Comma-separated list
    echo "$MODEL_FILTER" | tr ',' '\n'
    return
  fi

  # Read model names from config.yaml
  while IFS= read -r line; do
    local name
    name=$(echo "$line" | sed 's/^  - model_name: //')
    # Skip fallback models
    if [ "$name" = "fallback-deepseek" ]; then
      continue
    fi
    # Skip local models unless --local or --all
    if [ "$INCLUDE_ALL" = true ] || [ "$INCLUDE_LOCAL" = true ]; then
      echo "$name"
    else
      # Only include cloud models (those with API keys)
      case "$name" in
        deepseek-local|qwen2.5-coder|*-cloud|nomic-embed-text)
          # Skip local/cloud/free models unless --local or --all
          ;;
        *)
          echo "$name"
          ;;
      esac
    fi
  done < <(grep -E '^  - model_name:' "$SCRIPT_DIR/config.yaml")
}

# --- Benchmark a single model ---
benchmark_model() {
  local model="$1"
  local prompt="$2"
  local start_time end_time duration response

  start_time=$(date +%s%N 2>/dev/null || date +%s 2>/dev/null || echo 0)

  response=$(curl -sf "http://localhost:$PORT/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer anything" \
    -d "{
      \"model\": \"$model\",
      \"messages\": [{\"role\": \"user\", \"content\": $(echo "$prompt" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read().strip()))')}],
      \"max_tokens\": 200
    }" 2>/dev/null || echo "")

  end_time=$(date +%s%N 2>/dev/null || date +%s 2>/dev/null || echo 0)

  if [ -z "$response" ]; then
    echo "error|0|0|0|0|Request failed"
    return
  fi

  # Parse response
  local content tokens_in tokens_out cost duration_ms
  content=$(echo "$response" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    if 'error' in d:
        print('ERROR:' + str(d['error']))
        sys.exit(0)
    choice = d['choices'][0]['message']['content']
    usage = d.get('usage', {})
    tokens_in = usage.get('prompt_tokens', 0)
    tokens_out = usage.get('completion_tokens', 0)
    print(f'OK:{choice}:{tokens_in}:{tokens_out}')
except Exception as e:
    print(f'PARSE_ERROR:{e}')
" 2>/dev/null || echo "PARSE_ERROR:unknown")

  local status content_text
  status=$(echo "$response" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    if 'error' in d:
        print('error')
    else:
        print('ok')
except Exception:
    print('parse_error')
" 2>/dev/null || echo "parse_error")

  tokens_in=$(echo "$response" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('usage', {}).get('prompt_tokens', 0))
except Exception:
    print(0)
" 2>/dev/null || echo 0)

  tokens_out=$(echo "$response" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('usage', {}).get('completion_tokens', 0))
except Exception:
    print(0)
" 2>/dev/null || echo 0)

  # Calculate duration in ms
  if [[ "$start_time" =~ ^[0-9]+$ ]] && [[ "$end_time" =~ ^[0-9]+$ ]]; then
    if [ ${#start_time} -gt 12 ]; then
      # Nanosecond precision
      duration_ms=$(( (end_time - start_time) / 1000000 ))
    else
      duration_ms=$(( (end_time - start_time) * 1000 ))
    fi
  else
    duration_ms=0
  fi

  # Calculate cost
  local pricing_input pricing_output cost
  IFS=' ' read -r pricing_input pricing_output <<< "${MODEL_PRICING[$model]:-0 0}"
  cost=$(echo "scale=6; ($tokens_in * $pricing_input + $tokens_out * $pricing_output) / 1000000" | bc 2>/dev/null || echo 0)

  echo "$status|$duration_ms|$tokens_in|$tokens_out|$cost|"
}

# --- Print results ---
print_results() {
  local results_file="$1"
  if [ "$JSON_OUTPUT" = true ]; then
    python3 -c "
import csv, json, sys
rows = []
with open('$results_file') as f:
    reader = csv.DictReader(f)
    for row in reader:
        rows.append(row)
print(json.dumps(rows, indent=2))
"
  else
    # Pretty table
    printf "%-30s %-10s %-12s %-10s %-10s %s\n" "MODEL" "STATUS" "LATENCY(ms)" "TOKENS_IN" "TOKENS_OUT" "EST_COST(\$)"
    printf "%s\n" "----------------------------------------------------------------------------------------------------"
    while IFS=',' read -r model status duration tokens_in tokens_out cost; do
      if [ "$model" != "model" ]; then
        printf "%-30s %-10s %-12s %-10s %-10s %s\n" "$model" "$status" "$duration" "$tokens_in" "$tokens_out" "$cost"
      fi
    done < "$results_file"
  fi
}

# --- Main ---
echo "=== LiteLLM Model Benchmark ==="
echo "Proxy: http://localhost:$PORT"
echo "Prompts per model: $PROMPTS_COUNT"
echo ""

# Check proxy is running
if ! curl -sf "http://localhost:$PORT/health" --max-time 3 >/dev/null 2>&1; then
  echo "❌ Proxy is not running on port $PORT."
  echo "Start it first: ./start.sh"
  exit 1
fi

# Collect models
MODELS=()
while IFS= read -r m; do
  [ -n "$m" ] && MODELS+=("$m")
done < <(get_models)

if [ ${#MODELS[@]} -eq 0 ]; then
  echo "No models selected. Use --models, --local, or --all."
  exit 1
fi

echo "Models to benchmark: ${#MODELS[@]}"
for m in "${MODELS[@]}"; do
  echo "  - $m"
done
echo ""

# Generate output filename
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
if [ -z "$OUTPUT_FILE" ]; then
  OUTPUT_FILE="$LOG_DIR/benchmark-$TIMESTAMP.csv"
fi

# Write CSV header
echo "model,status,latency_ms,tokens_in,tokens_out,est_cost" > "$OUTPUT_FILE"

# Run benchmarks
TOTAL=$(( ${#MODELS[@]} * PROMPTS_COUNT ))
CURRENT=0

for model in "${MODELS[@]}"; do
  echo "Benchmarking: $model ..."
  for ((i=0; i<PROMPTS_COUNT; i++)); do
    CURRENT=$((CURRENT + 1))
    prompt="${BENCHMARK_PROMPTS[$i]}"
    printf "  [%d/%d] " "$CURRENT" "$TOTAL"

    result=$(benchmark_model "$model" "$prompt")
    status=$(echo "$result" | cut -d'|' -f1)
    duration=$(echo "$result" | cut -d'|' -f2)
    tokens_in=$(echo "$result" | cut -d'|' -f3)
    tokens_out=$(echo "$result" | cut -d'|' -f4)
    cost=$(echo "$result" | cut -d'|' -f5)

    echo "$model,$status,$duration,$tokens_in,$tokens_out,$cost" >> "$OUTPUT_FILE"

    if [ "$status" = "ok" ]; then
      echo "✅ ${duration}ms (${tokens_in}+${tokens_out} tokens, \$${cost})"
    else
      echo "❌ $status"
    fi
  done
done

echo ""
echo "=== Results ==="
echo ""

# Aggregate results by model
AGG_FILE="$LOG_DIR/benchmark-agg-$TIMESTAMP.csv"
python3 -c "
import csv
from collections import defaultdict

rows = defaultdict(lambda: {'status': 'ok', 'durations': [], 'tokens_in': 0, 'tokens_out': 0, 'costs': []})

with open('$OUTPUT_FILE') as f:
    reader = csv.DictReader(f)
    for row in reader:
        m = row['model']
        rows[m]['durations'].append(float(row['latency_ms']))
        rows[m]['tokens_in'] += int(row['tokens_in'])
        rows[m]['tokens_out'] += int(row['tokens_out'])
        rows[m]['costs'].append(float(row['est_cost']))
        if row['status'] != 'ok':
            rows[m]['status'] = row['status']

with open('$AGG_FILE', 'w') as f:
    w = csv.writer(f)
    w.writerow(['model', 'status', 'avg_latency_ms', 'min_latency_ms', 'max_latency_ms', 'total_tokens_in', 'total_tokens_out', 'total_cost'])
    for model in sorted(rows.keys()):
        d = rows[model]
        avg_lat = sum(d['durations']) / len(d['durations']) if d['durations'] else 0
        min_lat = min(d['durations']) if d['durations'] else 0
        max_lat = max(d['durations']) if d['durations'] else 0
        total_cost = sum(d['costs'])
        w.writerow([model, d['status'], f'{avg_lat:.0f}', f'{min_lat:.0f}', f'{max_lat:.0f}', d['tokens_in'], d['tokens_out'], f'{total_cost:.6f}'])
"

# Print aggregated results
printf "%-30s %-8s %-14s %-14s %-14s %s\n" "MODEL" "STATUS" "AVG_LATENCY" "MIN_LATENCY" "MAX_LATENCY" "TOTAL_COST"
printf "%s\n" "----------------------------------------------------------------------------------------------------"
while IFS=',' read -r model status avg_lat min_lat max_lat tokens_in tokens_out cost; do
  if [ "$model" != "model" ]; then
    printf "%-30s %-8s %-14s %-14s %-14s %s\n" "$model" "$status" "${avg_lat}ms" "${min_lat}ms" "${max_lat}ms" "\$${cost}"
  fi
done < "$AGG_FILE"

echo ""
echo "Raw results:  $OUTPUT_FILE"
echo "Aggregated:   $AGG_FILE"
