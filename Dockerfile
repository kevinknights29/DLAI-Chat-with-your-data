# Sources:
# https://jupyter-docker-stacks.readthedocs.io/en/latest/using/selecting.html
# https://jupyter-docker-stacks.readthedocs.io/en/latest/using/recipes.html#using-mamba-install-or-pip-install-in-a-child-docker-image
FROM jupyter/scipy-notebook:latest
LABEL authors="Kevin Knights | kevinknights29"

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
        # deps for building python deps
        build-essential \
        python3-dev \
        gcc

# Download Model
RUN mkdir -p /opt/models && \
    curl -L $MODEL_URL -o /opt/models/${MODEL_FILENAME}

# Install llama-cpp package for python
RUN pip install --no-cache-dir llama-cpp-python  && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# Install Jupyter Notebook extensions
RUN pip install --no-cache-dir jupyter_contrib_nbextensions && \
    jupyter contrib nbextension install --user && \
    # can modify or enable additional extensions here
    jupyter nbextension enable spellchecker/main --user && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# Adding theme configuration to JupyterLab
COPY ./overrides.json /opt/conda/share/jupyter/lab/settings/overrides.json

# Install from the requirements.txt file
COPY --chown=${NB_UID}:${NB_GID} requirements.txt /tmp/
RUN pip install --no-cache-dir --requirement /tmp/requirements.txt && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"
