#!/bin/bash
set -e

mkdir -p "$MODEL_DIR"

if [ ! -f "$MODEL_DIR/$GGUF_FILE" ]; then
  echo "Downloading $GGUF_FILE from $HF_REPO ..."
  hf download "$HF_REPO" "$GGUF_FILE" --local-dir "$MODEL_DIR"
fi

exec /opt/llama.cpp/build/bin/llama-server \
  -m "$MODEL_DIR/$GGUF_FILE" \
  --host 0.0.0.0 --port "$PORT" \
  -ngl 99 -fa on -c "$CTX_SIZE"
