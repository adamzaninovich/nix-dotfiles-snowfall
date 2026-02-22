{ pkgs, writeShellScriptBin, ... }:

writeShellScriptBin "transcribe-audio" ''
  set -euo pipefail

  COMPOSE_FILE="/opt/stacks/transcribe/compose.yaml"
  COMPOSE_DIR="$(${pkgs.coreutils}/bin/dirname "''${COMPOSE_FILE}")"
  SPEAKERS="1"
  HF_TOKEN="''${HF_TOKEN:-}"
  VERBOSE=0

  # Source .env from compose directory if it exists (for HF_TOKEN, etc.)
  if [[ -f "''${COMPOSE_DIR}/.env" ]]; then
    set -a
    source "''${COMPOSE_DIR}/.env"
    set +a
  fi

  usage() {
    echo "Usage: transcribe-audio [OPTIONS] <input-directory>"
    echo ""
    echo "Transcribe multi-track audio files using faster-whisper (large-v3)"
    echo "on GPU via Docker. Each audio file produces a per-speaker JSON"
    echo "(with word-level timestamps) and SRT file."
    echo ""
    echo "Supported formats: flac, wav, mp3, ogg, m4a, opus, webm"
    echo ""
    echo "Output is written to <input-directory>/transcripts/"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -v, --verbose           Show Docker build output"
    echo "  --speakers N|MIN-MAX    Expected speakers per file (default: 1)"
    echo "                          1 = no diarization"
    echo "                          N = exactly N speakers (e.g., 3)"
    echo "                          MIN-MAX = range (e.g., 2-6)"
    echo "  --hf-token TOKEN        HuggingFace token (or set HF_TOKEN env var)"
    echo "                          Required when --speakers > 1"
    echo ""
    echo "Examples:"
    echo "  transcribe-audio ~/sessions/2024-01-15/"
    echo "  transcribe-audio --speakers 4-6 ~/sessions/mixed-recording/"
    echo "  transcribe-audio --speakers 2 --hf-token hf_xxx ~/co-located/"
    exit 0
  }

  while [[ ''${#} -gt 0 ]]; do
    case "''${1}" in
      -h|--help) usage ;;
      -v|--verbose) VERBOSE=1; shift ;;
      --speakers)
        SPEAKERS="''${2}"
        shift 2
        ;;
      --hf-token)
        HF_TOKEN="''${2}"
        shift 2
        ;;
      -*) echo "Unknown option: ''${1}" >&2; exit 1 ;;
      *) break ;;
    esac
  done

  if [[ ''${#} -lt 1 ]]; then
    echo "Error: No input directory specified" >&2
    echo "" >&2
    usage
  fi

  # Validate --speakers format
  if ! [[ "''${SPEAKERS}" =~ ^[0-9]+(-[0-9]+)?$ ]]; then
    echo "Error: --speakers must be N or MIN-MAX (e.g., 3 or 2-6)" >&2
    exit 1
  fi

  # Determine if diarization is needed (max speakers > 1)
  max_spk="''${SPEAKERS##*-}"
  if [[ "''${max_spk}" -gt 1 ]] && [[ -z "''${HF_TOKEN}" ]]; then
    # Try to read from HuggingFace cache locations
    for token_file in "$HOME/.cache/huggingface/token" "$HOME/.huggingface/token"; do
      if [[ -f "''${token_file}" ]]; then
        HF_TOKEN=$(${pkgs.coreutils}/bin/cat "''${token_file}")
        echo "Using HuggingFace token from ''${token_file}"
        break
      fi
    done
    if [[ -z "''${HF_TOKEN}" ]]; then
      echo "Error: --speakers > 1 requires a HuggingFace token for pyannote diarization" >&2
      echo "" >&2
      echo "Options:" >&2
      echo "  1. Set HF_TOKEN environment variable" >&2
      echo "  2. Pass --hf-token TOKEN" >&2
      echo "  3. Run: pip install huggingface_hub && huggingface-cli login" >&2
      echo "" >&2
      echo "You must also accept the model licenses at:" >&2
      echo "  https://huggingface.co/pyannote/speaker-diarization-3.1" >&2
      echo "  https://huggingface.co/pyannote/segmentation-3.0" >&2
      exit 1
    fi
  fi

  input_dir="$(${pkgs.coreutils}/bin/realpath "''${1}")"

  if [[ ! -d "''${input_dir}" ]]; then
    echo "Error: Not a directory: ''${input_dir}" >&2
    exit 1
  fi

  # Check for audio files
  audio_count=0
  for ext in flac wav mp3 ogg m4a opus webm; do
    count=$(${pkgs.findutils}/bin/find "''${input_dir}" -maxdepth 1 -iname "*.''${ext}" -type f | ${pkgs.coreutils}/bin/wc -l)
    audio_count=$((audio_count + count))
  done

  if [[ "''${audio_count}" -eq 0 ]]; then
    echo "Error: No audio files found in ''${input_dir}" >&2
    echo "Supported formats: flac, wav, mp3, ogg, m4a, opus, webm" >&2
    exit 1
  fi

  echo "Found ''${audio_count} audio file(s) in ''${input_dir}"
  if [[ "''${max_spk}" -gt 1 ]]; then
    echo "Diarization: enabled (speakers: ''${SPEAKERS})"
  fi

  # Create output directory
  output_dir="''${input_dir}/transcripts"
  ${pkgs.coreutils}/bin/mkdir -p "''${output_dir}"
  echo "Output: ''${output_dir}"
  echo ""

  # Ensure Docker image is built
  if [[ "''${VERBOSE}" -eq 1 ]]; then
    echo "Building Docker image..."
    docker compose -f "''${COMPOSE_FILE}" build transcribe
  else
    echo "Building Docker image (use -v to show build output)..."
    docker compose -f "''${COMPOSE_FILE}" build --quiet transcribe
  fi
  echo ""

  # Run transcription
  INPUT_DIR="''${input_dir}" OUTPUT_DIR="''${output_dir}" \
    HF_TOKEN="''${HF_TOKEN}" SPEAKERS="''${SPEAKERS}" \
    docker compose -f "''${COMPOSE_FILE}" run --rm transcribe

  echo ""
  echo "Transcripts written to: ''${output_dir}"
''
