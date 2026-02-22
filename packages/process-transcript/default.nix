{ pkgs, writeShellScriptBin, ... }:

writeShellScriptBin "process-transcript" ''
  set -euo pipefail

  WEBHOOK_URL="https://n8n.protogen.cloud/webhook/process-transcript"

  usage() {
    echo "Usage: process-transcript [OPTIONS] <session-directory>"
    echo ""
    echo "Send a transcript JSON to n8n for processing into structured notes."
    echo ""
    echo "Looks for transcripts in <session-directory>/transcripts/."
    echo "Uses merged.json if present, otherwise the single .json file."
    echo ""
    echo "Output is written to <session-directory>/<dirname>-notes.md"
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message"
    echo ""
    echo "Examples:"
    echo "  process-transcript ~/sessions/session-1/"
    echo "  process-transcript ."
    exit 0
  }

  while [[ ''${#} -gt 0 ]]; do
    case "''${1}" in
      -h|--help) usage ;;
      -*) echo "Unknown option: ''${1}" >&2; exit 1 ;;
      *) break ;;
    esac
  done

  if [[ ''${#} -lt 1 ]]; then
    echo "Error: No session directory specified" >&2
    echo "" >&2
    usage
  fi

  session_dir="$(${pkgs.coreutils}/bin/realpath "''${1}")"

  if [[ ! -d "''${session_dir}" ]]; then
    echo "Error: Not a directory: ''${session_dir}" >&2
    exit 1
  fi

  transcript_dir="''${session_dir}/transcripts"
  if [[ ! -d "''${transcript_dir}" ]]; then
    echo "Error: No transcripts directory found at ''${transcript_dir}" >&2
    exit 1
  fi

  # Find the transcript JSON: prefer merged.json, fall back to single .json
  if [[ -f "''${transcript_dir}/merged.json" ]]; then
    json_file="''${transcript_dir}/merged.json"
  else
    json_files=()
    for f in "''${transcript_dir}"/*.json; do
      [[ -f "''${f}" ]] && json_files+=("''${f}")
    done

    if [[ ''${#json_files[@]} -eq 0 ]]; then
      echo "Error: No JSON files found in ''${transcript_dir}" >&2
      exit 1
    elif [[ ''${#json_files[@]} -gt 1 ]]; then
      echo "Error: Multiple JSON files found but no merged.json" >&2
      echo "Files found:" >&2
      for f in "''${json_files[@]}"; do
        echo "  - $(${pkgs.coreutils}/bin/basename "''${f}")" >&2
      done
      echo "Run transcribe-audio with multiple tracks to generate merged.json" >&2
      exit 1
    fi

    json_file="''${json_files[0]}"
  fi

  # Output file: <session-dir>/<dirname>-notes.md
  dir_name="$(${pkgs.coreutils}/bin/basename "''${session_dir}")"
  output_file="''${session_dir}/''${dir_name}-notes.md"

  echo "Transcript: $(${pkgs.coreutils}/bin/basename "''${json_file}")"
  echo "Sending to n8n for processing..."
  echo ""

  ${pkgs.curl}/bin/curl --max-time 1800 \
    -X POST "''${WEBHOOK_URL}" \
    -F "file=@''${json_file}" \
    -o "''${output_file}" \
    --fail-with-body \
    --progress-bar

  echo ""
  echo "Notes written to: ''${output_file}"
''
