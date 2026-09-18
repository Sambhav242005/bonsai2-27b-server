#!/bin/bash
set -e

mkdir -p "$MODEL_DIR"

if [ ! -f "$MODEL_DIR/$GGUF_FILE" ]; then
  echo "Downloading $GGUF_FILE from $HF_REPO ..."
  hf download "$HF_REPO" "$GGUF_FILE" --local-dir "$MODEL_DIR"
fi

if [ ! -f "$MODEL_DIR/$MMPROJ_FILE" ]; then
  echo "Downloading $MMPROJ_FILE from $HF_REPO ..."
  hf download "$HF_REPO" "$MMPROJ_FILE" --local-dir "$MODEL_DIR"
fi

exec /opt/llama.cpp/build/bin/llama-server \
  -m "$MODEL_DIR/$GGUF_FILE" \
  --mmproj "$MODEL_DIR/$MMPROJ_FILE" --mmproj-offload \
  --host 0.0.0.0 --port "$PORT" \
  -ngl 99 -fa on -c "$CTX_SIZE" \
  -ctk q4_0 -ctv q4_0