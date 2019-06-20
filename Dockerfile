FROM ubuntu:16.04

LABEL maintainer="Amazon AI"

ARG MMS_VERSION=1.0.4
ARG MX_VERSION=1.4.1

# Python won’t try to write .pyc or .pyo files on the import of source modules
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-8-jdk-headless \
    ca-certificates \
    curl \
    wget \
    git \
    vim \
    && rm -rf /var/lib/apt/lists/*


#Only majolr change ferom the cpu file
RUN pip install --no-cache https://s3.amazonaws.com/amazonei-apachemxnet/amazonei_mxnet-1.4.0-py2.py3-none-manylinux1_x86_64.whl \
keras-mxnet==2.2.4.1 \
onnx==1.4.1

# See http://bugs.python.org/issue19846
ENV LANG C.UTF-8

ARG PYTHON=python
ARG PYTHON_PIP=python-pip
ARG PIP=pip

RUN apt-get update && apt-get install -y \
    ${PYTHON} \
    ${PYTHON_PIP} \
    && rm -rf /var/lib/apt/lists/*

RUN ${PIP} --no-cache-dir install --upgrade pip setuptools

RUN ln -s $(which ${PYTHON}) /usr/local/bin/python

RUN ${PIP} install --no-cache-dir mxnet-mkl==$MX_VERSION \
                                  mxnet-model-server==$MMS_VERSION

RUN useradd -m model-server \
    && mkdir -p /home/model-server/tmp

COPY mms-entrypoint.sh /usr/local/bin/dockerd-entrypoint.sh
COPY config.properties /home/model-server

RUN chmod +x /usr/local/bin/dockerd-entrypoint.sh \
    && chown -R model-server /home/model-server

EXPOSE 8080 8081

USER model-server
WORKDIR /home/model-server
ENV TEMP=/home/model-server/tmp
ENTRYPOINT ["/usr/local/bin/dockerd-entrypoint.sh"]
CMD ["serve"]