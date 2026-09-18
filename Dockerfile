# Serves prism-ml/Ternary-Bonsai-2-27B-gguf on Lightning AI deployments.
#
# Stock llama.cpp / Ollama do NOT support this model's PQ2_0/PTQ1_0 ternary
# packing (they either reject the file or load it with wrong output).
# This image builds PrismML's own llama.cpp fork, which has the required
# ternary hybrid-attention kernels.
#
# Model weights are NOT baked in here - they download on first container
# start (see entrypoint.sh). That keeps this image small enough to build
# on a free GitHub Actions runner; see build-push.yml.

FROM nvidia/cuda:12.4.1-devel-ubuntu22.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    git cmake build-essential python3 python3-pip curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir "huggingface_hub[cli]"

# Build PrismML's llama.cpp fork (branch: prism) with CUDA support.
RUN git clone -b prism https://github.com/PrismML-Eng/llama.cpp.git /opt/llama.cpp
WORKDIR /opt/llama.cpp
# CMAKE_CUDA_ARCHITECTURES is set explicitly because this build runs on a
# GitHub Actions runner with no physical GPU, so CMake can't auto-detect
# one. The list below covers V100 (70), T4 (75), A100 (80), A10G/RTX30xx
# (86), L4/Ada/RTX40xx (89), and H100 (90) - the GPU families you're
# likely to pick on Lightning AI.
RUN cmake -B build -DGGML_CUDA=ON -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CUDA_ARCHITECTURES="70;75;80;86;89;90" \
    && cmake --build build -j "$(nproc)" --target llama-server

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# PQ2_0 (7.21GB) is best on H100/A100/5090/Blackwell.
# On an Ada-class GPU (L4, RTX 4090, L40S, RTX 6000 Ada) set GGUF_FILE to
# Ternary-Bonsai-2-27B-PTQ1_0.gguf instead (5.95GB, faster decode there) -
# either via this default or an env var override in the Lightning UI.
ENV HF_REPO=prism-ml/Ternary-Bonsai-2-27B-gguf
ENV GGUF_FILE=Ternary-Bonsai-2-27B-PQ2_0.gguf
ENV MODEL_DIR=/models
ENV CTX_SIZE=32768
ENV PORT=8080

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
