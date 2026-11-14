# shellcheck shell=sh disable=SC2034,SC2154
# Variables are supplied by the calling vee script.
# Source as ./vee-custom.sh. Select with -f groff-utf8 (or -f null).
format_with_null() { with_no_formatting; }
format_with_groff_utf8()
{
  if command -v groff-utf8 >/dev/null 2>&1; then
    _UTF8_GROFF=groff-utf8
  elif command -v groff >/dev/null 2>&1; then
    _UTF8_GROFF=groff
  else
    die_error 'groff is not installed'
  fi
  if [ "$_OUTPUT_TYPE" = html ]; then
    "$_UTF8_GROFF" -man -Tutf8 "$RAW" > "$WORK/utf8"
    sed '/^$/N;/\n$/D' "$WORK/utf8" >> "$FINAL"
  else
    "$_UTF8_GROFF" -man -Tutf8 "$gRAW" > "$WORK/utf8"
    sed '/^$/N;/\n$/D' "$WORK/utf8" > "$gFINAL"
  fi
}
custom_set_format_func()
{
  case $1 in
    null) FORMAT_FUNC=format_with_null;;
    groff-utf8) FORMAT_FUNC=format_with_groff_utf8;;
    *) die_error "bad format type: $1";;
  esac
}
# Keep the historical extension function names while using current filenames.
custom_update_index() { default_update_index "$@"; }
custom_output_top() { output_top; }
custom_output_bottom() { output_bottom; }
