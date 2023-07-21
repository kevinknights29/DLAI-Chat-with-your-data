# Sources:
# https://jupyter-docker-stacks.readthedocs.io/en/latest/using/selecting.html
# https://jupyter-docker-stacks.readthedocs.io/en/latest/using/recipes.html#using-mamba-install-or-pip-install-in-a-child-docker-image
FROM jupyter/scipy-notebook:latest
LABEL authors="Kevin Knights | kevinknights29"

ARG MODEL_FOLDER=llama-2
ARG MODEL_FILENAME=llama-2-7b.ggmlv3.q4_0.bin
ARG MODEL_URL=https://huggingface.co/TheBloke/Llama-2-7B-GGML/resolve/main/llama-2-7b.ggmlv3.q4_0.bin

# Enable JupyterLab
ENV JUPYTER_ENABLE_LAB=yes

# Set llama.cpp environment variables for python
ENV CMAKE_ARGS="-DLLAMA_CUBLAS=on" \
    FORCE_CMAKE=1

# Switch to root to install packages
USER root

# Install system packages
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        # deps for downloading model
        curl \
        git \
        # deps for building python deps
        build-essential \
        python3-dev \
        gcc

# Download Model - Llama-2-7B-GGML
RUN mkdir -p /opt/models/${MODEL_FOLDER} && \
    curl -L $MODEL_URL -o /opt/models/${MODEL_FOLDER}/${MODEL_FILENAME}

# Download Model - Whisper.cpp
RUN git clone https://github.com/ggerganov/whisper.cpp.git /opt/models/whisper && \
    cd /opt/models/whisper && \
    bash ./models/download-ggml-model.sh base.en && \
    make base.en

# Install llama-cpp package for python
RUN pip install --no-cache-dir llama-cpp-python  && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# Extensions for JupyterLab can be found: https://jupyterlab-contrib.github.io/migrate_from_classical.html
# Install JupyterLab LSP extension
RUN pip install --no-cache-dir jupyterlab-lsp 'python-lsp-server[all]' && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# Install JupyterLab Code Formatter extension
RUN pip install --no-cache-dir jupyterlab-code-formatter black isort && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# Install JupyterLab Execute Time extension
RUN pip install --no-cache-dir jupyterlab_execute_time && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# Install JupyterLab Spell Checker extension
RUN pip install --no-cache-dir jupyterlab-spellchecker && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# Adding theme configuration to JupyterLab
COPY ./overrides.json /opt/conda/share/jupyter/lab/settings/overrides.json

# Install from the requirements.txt file
COPY --chown=${NB_UID}:${NB_GID} requirements.txt /tmp/
RUN pip install --no-cache-dir --requirement /tmp/requirements.txt && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"
