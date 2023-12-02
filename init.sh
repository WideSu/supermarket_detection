#!/usr/bin/env bash

set -euox pipefail
XTRACE=${XTRACE:-false}
if [[ "$XTRACE" = "true" ]]; then
    set -x
fi
IFS=$'\n\t'
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# upgrade pip to latest version
python3 -m pip install --upgrade pip
python3 -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))"
python3 -m pip install tf-models-official
# Install python packages
pip install -r ${DIR}/requirements.txt

TENSORFLOW_MODEL_GARDEN_DIR="${DIR}/tensorflow_model_garden"
WORKSPACE_DIR="${DIR}/workspace"


SKIP_CLONE=false
while getopts "s" FLAG; do
    case "${FLAG}" in
        s) SKIP_CLONE=true ;;
    esac
done

if ! command -v git &> /dev/null; then
    echo "You must install 'git' in order to run this script"
    exit
fi

if [ ${SKIP_CLONE} = false ]; then
    if [ -d "${TENSORFLOW_MODEL_GARDEN_DIR}" ]; then
        echo "Deleting existing directory ${TENSORFLOW_MODEL_GARDEN_DIR}"
        rm -rf "${TENSORFLOW_MODEL_GARDEN_DIR}"
    fi

    echo "Cloning https://github.com/tensorflow/models"
    git clone --depth 1 https://github.com/tensorflow/models "${TENSORFLOW_MODEL_GARDEN_DIR}"
fi

cd "${TENSORFLOW_MODEL_GARDEN_DIR}"

echo "Installing protobuf"
pip install protobuf

if command -v protoc &> /dev/null; then
    echo "Found protoc"
else
    echo "Installing protoc"
    if [ $(uname -s) == "Darwin" ]; then
        PROTOC_ZIP=protoc-3.7.1-osx-x86_64.zip
    else
        PROTOC_ZIP=protoc-3.7.1-linux-x86_64.zip
    fi

    curl -OL https://github.com/google/protobuf/releases/download/v3.7.1/${PROTOC_ZIP}
    unzip -o ${PROTOC_ZIP} -d /usr/local bin/protoc
    unzip -o ${PROTOC_ZIP} -d /usr/local include/*
    rm -f ${PROTOC_ZIP}
fi


# echo "Installing tf_slim"
# pip install tf_slim

echo "Install the Object Detection API"
cd research/
protoc object_detection/protos/*.proto --python_out=.
cp object_detection/packages/tf2/setup.py .
python -m pip install .

echo "Installation complete"


# pip install cython
# pip install git+https://github.com/philferriere/cocoapi.git#subdirectory=PythonAPI