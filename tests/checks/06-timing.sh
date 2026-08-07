#!/bin/sh
# The durations a run ends with: the clock behind them, and the block itself.
#
# The clock is the part that travels badly -- `date +%N` is GNU's alone, and a
# fallback that silently answers in seconds would fill the block with zeroes
# that read like measurements. So the resolution is measured against a sleep
# rather than assumed, and a machine with nothing better than whole seconds
# says so here too.
#
# It sources the helpers and calls them, reading neither the repository nor
# the home directory, so it runs before the installed checks.

set -u

. "$(dirname -- "$0")/../lib.sh"
. "$(dirname -- "$0")/../timing.sh"

timing_init

# --- the clock -------------------------------------------------------------

now=$(now_ms)

case $now in
'' | *[!0-9]*)
    fail "now_ms answers in digits" "now_ms=$now, clock=$TEST_CLOCK"
    ;;
*)
    pass "now_ms answers in digits"
    ;;
esac

# Milliseconds have been 13 digits since 2001 and stay 13 until 2286, so a
# shorter answer is a clock in seconds wearing a millisecond label.
assert_equal "now_ms answers in milliseconds, not seconds" \
    "13" "${#now}"

if [ "$TEST_CLOCK" = seconds ]; then
    skip "a second of sleep measures a second (clock: whole seconds only)"
else
    started=$(now_ms)
    sleep 1
    elapsed=$(($(now_ms) - started))

    # Loose on both sides on purpose: the point is that the clock moves with
    # the sleep, not that a shared CI runner sleeps to the millisecond.
    if [ "$elapsed" -ge 900 ] && [ "$elapsed" -le 3000 ]; then
        pass "a second of sleep measures a second"
    else
        fail "a second of sleep measures a second" \
            "$elapsed ms, clock=$TEST_CLOCK"
    fi
fi

# --- the block -------------------------------------------------------------

assert_equal "milliseconds below a second" "0 ms" "$(fmt_duration 0)"
assert_equal "milliseconds up to the last one" "999 ms" "$(fmt_duration 999)"
assert_equal "a second reads as seconds" "1.0 s" "$(fmt_duration 1000)"
assert_equal "a tenth of a second survives" "1.4 s" "$(fmt_duration 1450)"
assert_equal "a long run keeps its seconds" "125.0 s" "$(fmt_duration 125000)"

report=$(printf '%s\n' "812 install" "55 05-handbook" "125000 total" |
    timing_report)

assert_equal "the block lines the durations up under each other" \
    "#   812 ms  install
#    55 ms  05-handbook
#  125.0 s  total" "$report"
