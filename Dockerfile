FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y \
    git \
    mpich \
    openssh-client \
    openssh-server \
    python3.10 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Install dependencies:
COPY . /mlperf
WORKDIR /mlperf
RUN git clone https://github.com/argonne-lcf/dlio_benchmark.git
RUN pip install --upgrade pip
RUN pip install -r dlio_benchmark/requirements.txt

# Enable root login via SSH
RUN sed -i "s/^PermitRootLogin .*/PermitRootLogin yes/g" /etc/ssh/sshd_config
RUN sed -i '/^#PermitRootLogin .*/a PermitRootLogin yes' /etc/ssh/sshd_config

ENTRYPOINT ["/mlperf/docker-entrypoint.sh"]
CMD ["/mlperf/benchmark.sh"]
