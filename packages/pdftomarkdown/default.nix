{ pkgs, writeShellScriptBin, ... }:

writeShellScriptBin "pdftomarkdown" ''
  set -euo pipefail

  usage() {
    echo "Usage: pdftomarkdown <input.pdf> [output.md]"
    echo ""
    echo "Convert a PDF file to Markdown using pdftotext and pandoc."
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -l, --layout   Preserve original layout (default: raw text)"
    echo "  --html         Use pdftohtml for better structure (slower)"
    echo ""
    echo "If output is omitted, writes to <input>.md"
    exit 0
  }

  layout_flag="-raw"
  use_html=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) usage ;;
      -l|--layout) layout_flag="-layout"; shift ;;
      --html) use_html=true; shift ;;
      -*) echo "Unknown option: $1" >&2; exit 1 ;;
      *) break ;;
    esac
  done

  if [[ $# -lt 1 ]]; then
    echo "Error: No input file specified" >&2
    usage
  fi

  input="$1"
  output="''${2:-''${input%.pdf}.md}"

  if [[ ! -f "$input" ]]; then
    echo "Error: File not found: $input" >&2
    exit 1
  fi

  if $use_html; then
    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT
    ${pkgs.poppler_utils}/bin/pdftohtml -s -noframes "$input" "$tmpdir/output.html"
    ${pkgs.pandoc}/bin/pandoc "$tmpdir/output.html" -t markdown -o "$output"
  else
    ${pkgs.poppler_utils}/bin/pdftotext $layout_flag "$input" - | \
      ${pkgs.pandoc}/bin/pandoc -t markdown -o "$output"
  fi

  echo "Converted: $input -> $output"
''
