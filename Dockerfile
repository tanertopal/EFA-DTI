# Copyright 2021 Adap GmbH. All Rights Reserved.

# Build with
#
# docker build \
#   --file poetry.Dockerfile .

# We are going to use a nvidia image which has all the cuda related
# depedencies pre installed.
FROM nvidia/cuda:11.1-cudnn8-devel-ubuntu20.04

# Set these envs explicitly as some torch extensions need them 
# while installing
ENV CUDA_HOME=/usr/local/cuda
ENV CPATH=/usr/local/cuda/include

# Set lang as e.g. Anaconda install needs it
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# Override system default which is `newt`
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update \
    # Anaconda dependencies
    && apt-get install -y --no-install-recommends \
        libgl1-mesa-glx \
        libegl1-mesa \
        libxrandr2 \
        libxrandr2 \
        libxss1 \
        libxcursor1 \
        libxcomposite1 \
        libasound2 \
        libxi6 \
        libxtst6 \
        bzip2 \
        ca-certificates \
        git \
        libglib2.0-0 \
        libsm6 \
        libxext6 \
        libxrender1 \
        mercurial \
        openssh-client \
        procps \
        subversion \
        wget \
        g++ \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install miniconda3
# Leave these args here to better use the Docker build cache
ENV PATH /opt/conda/bin:$PATH
ARG CONDA_VERSION=py39_4.10.3

RUN set -x && \
    UNAME_M="$(uname -m)" && \
    if [ "${UNAME_M}" = "x86_64" ]; then \
        MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-${CONDA_VERSION}-Linux-x86_64.sh"; \
        SHA256SUM="1ea2f885b4dbc3098662845560bc64271eb17085387a70c2ba3f29fff6f8d52f"; \
    elif [ "${UNAME_M}" = "s390x" ]; then \
        MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-${CONDA_VERSION}-Linux-s390x.sh"; \
        SHA256SUM="1faed9abecf4a4ddd4e0d8891fc2cdaa3394c51e877af14ad6b9d4aadb4e90d8"; \
    elif [ "${UNAME_M}" = "aarch64" ]; then \
        MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-${CONDA_VERSION}-Linux-aarch64.sh"; \
        SHA256SUM="4879820a10718743f945d88ef142c3a4b30dfc8e448d1ca08e019586374b773f"; \
    elif [ "${UNAME_M}" = "ppc64le" ]; then \
        MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-${CONDA_VERSION}-Linux-ppc64le.sh"; \
        SHA256SUM="fa92ee4773611f58ed9333f977d32bbb64769292f605d518732183be1f3321fa"; \
    fi && \
    wget "${MINICONDA_URL}" -O miniconda.sh -q && \
    echo "${SHA256SUM} miniconda.sh" > shasum && \
    if [ "${CONDA_VERSION}" != "latest" ]; then sha256sum --check --status shasum; fi && \
    mkdir -p /opt && \
    sh miniconda.sh -b -p /opt/conda && \
    rm miniconda.sh shasum && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc && \
    find /opt/conda/ -follow -type f -name '*.a' -delete && \
    find /opt/conda/ -follow -type f -name '*.js.map' -delete && \
    /opt/conda/bin/conda clean -afy

# Set working directory
WORKDIR /app

# Install dependencies
COPY KAICD.yaml .
RUN conda env create -f KAICD.yaml

# Copy code
COPY . .

# Set entrypoint to start application
ENV PYTHONPATH="./"
CMD ["conda", "run", "--no-capture-output", "-n", "KAICD", "python", "efa_dti/efa_dti_main.py"]