# Sources:
# https://jupyter-docker-stacks.readthedocs.io/en/latest/using/selecting.html
# https://jupyter-docker-stacks.readthedocs.io/en/latest/using/recipes.html#using-mamba-install-or-pip-install-in-a-child-docker-image
FROM jupyter/scipy-notebook:latest
LABEL authors="Kevin Knights | kevinknights29"

# Install from the requirements.txt file
COPY --chown=${NB_UID}:${NB_GID} requirements.txt /tmp/
RUN pip install --no-cache-dir --requirement /tmp/requirements.txt && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# Install Jupyter Notebook extensions
RUN pip install --no-cache-dir jupyter_contrib_nbextensions && \
    jupyter contrib nbextension install --user && \
    # can modify or enable additional extensions here
    jupyter nbextension enable spellchecker/main --user && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# Enable JupyterLab
ENV JUPYTER_ENABLE_LAB=yes

# Adding theme configuration to JupyterLab
COPY ./overrides.json /opt/conda/share/jupyter/lab/settings/overrides.json