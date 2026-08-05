# Timing, sourced by `tests/run` and by the check that covers it.
#
# What is timed, and how to turn it off: handbook/testing/README.md.
#
# The suite is one step of one CI job, and a slow check is invisible inside
# it: the job reports that the step took two minutes, and nothing says which
# of the checks spent them. So the run times itself -- the install it starts
# with, every check after it, and the whole run -- and ends with a block of
# durations that says where the time went.
#
# There is no millisecond clock in POSIX sh, and none that every machine has:
# `%N` is GNU date's and BSD date has nothing like it, while perl and python3
# both carry a sub-second clock wherever they are installed.
# `date +%s` is the floor, and whole seconds are too coarse to attribute
# anything, so a run that falls back to it says so rather than reporting
# a column of zeroes as if they were measurements.

# timing_clock -- the finest clock this machine has, named for now_ms.
timing_clock() {
    # What a date without %N prints instead is not the time, and it is not
    # always obvious either: the letter comes back, or the field width does,
    # and digits that survive would be taken for a clock. So the answer
    # counts only when it is digits throughout *and* exactly the three
    # digits longer than seconds that milliseconds are.
    _seconds=$(date +%s)
    _millis=$(date +%s%3N 2>/dev/null)

    case $_millis in
    '' | *[!0-9]*) ;;
    *)
        if [ "${#_millis}" -eq "$((${#_seconds} + 3))" ]; then
            echo date
            return 0
        fi
        ;;
    esac

    if command -v perl >/dev/null 2>&1; then
        echo perl
        return 0
    fi

    if command -v python3 >/dev/null 2>&1; then
        echo python3
        return 0
    fi

    echo seconds
}

# timing_init -- settle the clock before the first measurement.
#
# now_ms is called from command substitutions, and what such a subshell
# learns is lost when it exits: without this, every measurement would look
# the clock up again, and the caller would never see which one was found.
timing_init() {
    TEST_CLOCK=${TEST_CLOCK:-$(timing_clock)}
    export TEST_CLOCK
}

# now_ms -- the wall clock in milliseconds.
now_ms() {
    case ${TEST_CLOCK:=$(timing_clock)} in
    date) date +%s%3N ;;
    perl) perl -MTime::HiRes=time -e 'printf "%.0f\n", time() * 1000' ;;
    python3) python3 -c 'import time; print(round(time.time() * 1000))' ;;
    seconds) echo $(($(date +%s) * 1000)) ;;
    esac
}

# fmt_duration MILLISECONDS -- `812 ms` below a second, `1.4 s` above it.
#
# Two digits of precision throughout, because the durations are read against
# each other: a check that takes a tenth of the run is what the block is for,
# and no decision here turns on the third digit.
fmt_duration() {
    if [ "$1" -lt 1000 ]; then
        printf '%d ms' "$1"
    else
        printf '%d.%d s' $(($1 / 1000)) $(($1 % 1000 / 100))
    fi
}

# timing_report -- render `MILLISECONDS LABEL` lines read from stdin as the
# comment block a run ends with, the durations right-aligned against each
# other. Reading from stdin rather than from a variable is what lets a check
# feed it durations of its own.
timing_report() {
    while read -r ms label; do
        printf '# %8s  %s\n' "$(fmt_duration "$ms")" "$label"
    done
}
