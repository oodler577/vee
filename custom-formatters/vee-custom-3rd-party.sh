# shellcheck shell=sh disable=SC2034,SC2154
# Variables are supplied by the calling vee script.
# Optional HTML formatters. Source as ./vee-custom.sh through vee's extension API.
# Gopher remains plain text; external tools are needed only for HTML output.
format_with_par72()
{
  if [ "$_OUTPUT_TYPE" = gopher ]; then with_no_formatting; return; fi
  command -v par >/dev/null 2>&1 || die_error 'par is not installed'
  par -w 72 < "$RAW" >> "$FINAL"
}
format_with_pandoc()
{
  if [ "$_OUTPUT_TYPE" = gopher ]; then with_no_formatting; return; fi
  command -v pandoc >/dev/null 2>&1 || die_error 'pandoc is not installed'
  pandoc --from=markdown --to=html < "$RAW" >> "$FINAL"
}
format_with_markdown()
{
  if [ "$_OUTPUT_TYPE" = gopher ]; then with_no_formatting; return; fi
  command -v markdown >/dev/null 2>&1 || die_error 'markdown is not installed'
  markdown < "$RAW" >> "$FINAL"
}
# Preserve the misspelled legacy function name for existing configurations.
format_with_mardown() { format_with_markdown; }
custom_set_format_func()
{
  case $1 in
    par72) FORMAT_FUNC=format_with_par72;;
    pandoc) FORMAT_FUNC=format_with_pandoc;;
    markdown) FORMAT_FUNC=format_with_markdown;;
    *) die_error "bad format type: $1";;
  esac
}
