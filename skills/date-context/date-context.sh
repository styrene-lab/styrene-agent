#!/bin/bash
# date-context.sh - Compute working week boundaries
# Outputs structured date context to eliminate AI date calculation errors
# Cross-platform: macOS (BSD date) and Linux (GNU date)

# Detect date command flavor
if date --version >/dev/null 2>&1; then
  DATE_FLAVOR="gnu"
else
  DATE_FLAVOR="bsd"
fi

# Helper: add/subtract days from a date
# Usage: date_add "2026-01-25" -3  -> outputs date 3 days earlier
date_add() {
  local base_date=$1
  local days=$2
  if [[ "$DATE_FLAVOR" == "gnu" ]]; then
    date -d "$base_date $days days" "+%Y-%m-%d"
  else
    # BSD date: convert to epoch, add seconds, convert back
    local epoch=$(date -j -f "%Y-%m-%d" "$base_date" "+%s" 2>/dev/null)
    local new_epoch=$((epoch + days * 86400))
    date -r "$new_epoch" "+%Y-%m-%d"
  fi
}

# Helper: format date as "Mon D"
format_short() {
  local ymd=$1
  local month=$(echo "$ymd" | cut -d'-' -f2)
  local day=$(echo "$ymd" | cut -d'-' -f3 | sed 's/^0//')
  case $month in
    01) mon="Jan" ;; 02) mon="Feb" ;; 03) mon="Mar" ;;
    04) mon="Apr" ;; 05) mon="May" ;; 06) mon="Jun" ;;
    07) mon="Jul" ;; 08) mon="Aug" ;; 09) mon="Sep" ;;
    10) mon="Oct" ;; 11) mon="Nov" ;; 12) mon="Dec" ;;
  esac
  echo "$mon $day"
}

# Get today's info
TODAY=$(date "+%Y-%m-%d")
TODAY_DOW=$(date "+%A")
DOW_NUM=$(date "+%u")  # 1=Monday, 7=Sunday

# Calculate week boundaries
DAYS_SINCE_MON=$((DOW_NUM - 1))
CURR_MON=$(date_add "$TODAY" "-$DAYS_SINCE_MON")
CURR_FRI=$(date_add "$CURR_MON" "4")

PREV_MON=$(date_add "$CURR_MON" "-7")
PREV_FRI=$(date_add "$PREV_MON" "4")

# Extract years for range formatting
CURR_MON_YEAR=$(echo "$CURR_MON" | cut -d'-' -f1)
CURR_FRI_YEAR=$(echo "$CURR_FRI" | cut -d'-' -f1)
PREV_MON_YEAR=$(echo "$PREV_MON" | cut -d'-' -f1)
PREV_FRI_YEAR=$(echo "$PREV_FRI" | cut -d'-' -f1)

# Format short dates
CURR_MON_FMT=$(format_short "$CURR_MON")
CURR_FRI_FMT=$(format_short "$CURR_FRI")
PREV_MON_FMT=$(format_short "$PREV_MON")
PREV_FRI_FMT=$(format_short "$PREV_FRI")

# Build range strings (handle year boundaries)
if [ "$CURR_MON_YEAR" = "$CURR_FRI_YEAR" ]; then
  CURR_WEEK_RANGE="$CURR_MON_FMT - $CURR_FRI_FMT, $CURR_FRI_YEAR"
else
  CURR_WEEK_RANGE="$CURR_MON_FMT, $CURR_MON_YEAR - $CURR_FRI_FMT, $CURR_FRI_YEAR"
fi

if [ "$PREV_MON_YEAR" = "$PREV_FRI_YEAR" ]; then
  PREV_WEEK_RANGE="$PREV_MON_FMT - $PREV_FRI_FMT, $PREV_FRI_YEAR"
else
  PREV_WEEK_RANGE="$PREV_MON_FMT, $PREV_MON_YEAR - $PREV_FRI_FMT, $PREV_FRI_YEAR"
fi

echo "DATE_CONTEXT:"
echo "  TODAY: $TODAY ($TODAY_DOW)"
echo "  CURR_WEEK_START: $CURR_MON (Monday)"
echo "  CURR_WEEK_END: $CURR_FRI (Friday)"
echo "  CURR_WEEK_RANGE: $CURR_WEEK_RANGE"
echo "  PREV_WEEK_START: $PREV_MON (Monday)"
echo "  PREV_WEEK_END: $PREV_FRI (Friday)"
echo "  PREV_WEEK_RANGE: $PREV_WEEK_RANGE"
