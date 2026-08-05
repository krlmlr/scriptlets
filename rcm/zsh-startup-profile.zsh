#
# zsh startup instrumentation -- installed as ~/.zsh-startup-profile.zsh,
# sourced from the first line of ~/.zshenv, never executed.
#
# Two jobs, one file:
#
#   1. ALWAYS ON -- time every interactive startup and append one line to the
#      log. The number worth having is the one from real shells on a real
#      machine, over weeks, not the one from a clean-room benchmark run once.
#   2. ON REQUEST -- load zsh/zprof so a single startup can be broken down per
#      function. That one is opt-in because zprof instruments every function
#      call and distorts the very number being measured.
#
# ~/.zshenv is the first file every zsh reads, which is why the fragment is
# sourced from there: the measurement then covers the whole rc chain
# (.zshenv -> .zprofile -> .zshrc), not just the tail of it.
#
# Non-interactive shells (every script, every `zsh -c`) leave after two builtin
# statements. Interactive ones pay one precmd hook that runs once, before the
# first prompt, and unhooks itself.
#
# `zsh -i -c 'exit 0'` never reaches a prompt, so benchmark runs do NOT write to
# the log -- benchmark noise stays out of the production record by construction.
#
# Reading the numbers, and turning any of this off:
# handbook/config/zsh-startup/README.md in the scriptlets repository.
#
# Knobs, all optional, all read from the environment -- and from
# ~/scriptlets/zsh-startup, which is sourced first and is the place to set them
# on one machine without touching the dotfiles every machine shares:
#
#   ZSH_STARTUP_PROFILE     0 or empty: do nothing at all. The off switch;
#                           anything else, including unset, leaves it on.
#   ZSH_STARTUP_LOG         where to append; empty disables logging entirely
#                           (default $XDG_STATE_HOME/zsh-startup.log, i.e.
#                           ~/.local/state/zsh-startup.log)
#   ZSH_STARTUP_BUDGET_MS   print a one-line notice when startup exceeds this
#                           many milliseconds. Default 0 -- every startup
#                           exceeds 0, so every startup reports itself, which
#                           is what you want while the config is being built up
#                           install by install. Set it to a real budget (500)
#                           once the number is boring and only regressions
#                           should speak up; set it empty to say nothing.
#   ZSH_STARTUP_ZPROF       non-empty: load zsh/zprof and print the breakdown
#                           before the first prompt
#   ZSH_STARTUP_MARKS       non-empty: break the notice above down into the
#                           checkpoint timeline collected by zsh_startup_mark
#                           (see below). ~/.zshenv turns it on by default, and
#                           the marks sit at the end of each of the three
#                           startup files. The timeline is only ever printed
#                           under the notice it explains, so a budget that
#                           silences one silences both.

# Sourced before anything else happens, so that it can turn the rest off. A
# file that is not there costs one stat and no fork.
[[ -r $HOME/scriptlets/zsh-startup ]] && source $HOME/scriptlets/zsh-startup

# The off switch. ~/.zshenv defines a no-op zsh_startup_mark when this file
# defines nothing, so the marks left behind in the three startup files stay
# harmless.
case ${ZSH_STARTUP_PROFILE-1} in
  ''|0|no|off|false) return 0 ;;
esac

zmodload zsh/datetime
: ${ZSH_STARTUP_T0:=$EPOCHREALTIME}

# Checkpoints. Call `zsh_startup_mark <label>` anywhere in the rc chain -- at
# the end of ~/.zprofile, at the end of ~/.zshrc, around a suspect block -- and
# the first prompt prints the timeline. This is the only instrument that sees
# the real session: a benchmark shell has no tty, no terminal integration and
# no prompt, so anything the terminal itself costs is invisible to hyperfine
# and shows up here as the gap between the last mark and the prompt.
#
# Defined before the interactive guard so a mark in ~/.zshenv is safe in
# scripts too. Two array appends, no forks.
typeset -ga ZSH_STARTUP_MARK_AT ZSH_STARTUP_MARK_LABEL
zsh_startup_mark() {
  ZSH_STARTUP_MARK_AT+=( $(( (EPOCHREALTIME - ZSH_STARTUP_T0) * 1000 )) )
  ZSH_STARTUP_MARK_LABEL+=( ${1:-mark} )
}

[[ -o interactive ]] || return 0

[[ -n ${ZSH_STARTUP_ZPROF:-} ]] && zmodload zsh/zprof

: ${ZSH_STARTUP_LOG=${XDG_STATE_HOME:-$HOME/.local/state}/zsh-startup.log}
# `=` rather than `:=`, so an explicitly empty value survives and stays silent.
: ${ZSH_STARTUP_BUDGET_MS=0}

_zsh_startup_record() {
  add-zsh-hook -d precmd _zsh_startup_record

  local -F ms=$(( (EPOCHREALTIME - ZSH_STARTUP_T0) * 1000 ))

  if [[ -n $ZSH_STARTUP_LOG ]]; then
    local dir=${ZSH_STARTUP_LOG:h} stamp kind=interactive
    [[ -o login ]] && kind=login
    strftime -s stamp '%Y-%m-%dT%H:%M:%S%z' $EPOCHSECONDS
    [[ -d $dir ]] || mkdir -p $dir
    # One short line, opened and closed per shell: concurrent terminals append
    # without stepping on each other, and any editor can read it. `>>|` appends
    # even under noclobber, including the very first time.
    printf '%s\t%.0f\t%s\t%s\n' \
      $stamp $ms ${TERM_PROGRAM:-unknown} $kind >>| $ZSH_STARTUP_LOG
  fi

  local -i speaks=0
  if [[ -n $ZSH_STARTUP_BUDGET_MS ]] && (( ms > ZSH_STARTUP_BUDGET_MS )); then
    speaks=1
    if (( ZSH_STARTUP_BUDGET_MS > 0 )); then
      printf 'zsh startup %.0f ms (budget %s ms) -- zsh-startup-bench\n' \
        $ms $ZSH_STARTUP_BUDGET_MS >&2
    else
      printf 'zsh startup %.0f ms\n' $ms >&2
    fi
  fi

  # Only ever under the line it breaks down. A timeline on its own would be a
  # report from a startup that was told to keep quiet, and a budget that still
  # printed five lines per prompt would not be a way to quieten anything.
  if (( speaks )) && [[ -n ${ZSH_STARTUP_MARKS:-} ]] && (( $#ZSH_STARTUP_MARK_AT )); then
    local -F prev=0
    local i
    for i in {1..$#ZSH_STARTUP_MARK_AT}; do
      printf '  %7.1f ms  %-16s (+%.1f)\n' \
        $ZSH_STARTUP_MARK_AT[i] $ZSH_STARTUP_MARK_LABEL[i] \
        $(( ZSH_STARTUP_MARK_AT[i] - prev )) >&2
      prev=$ZSH_STARTUP_MARK_AT[i]
    done
    printf '  %7.1f ms  %-16s (+%.1f)\n' $ms 'first prompt' $(( ms - prev )) >&2
  fi

  [[ -n ${ZSH_STARTUP_ZPROF:-} ]] && zprof

  return 0
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _zsh_startup_record
