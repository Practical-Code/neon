#!/bin/bash
# ******************************************************************************
# Copyright 2017-2018 Intel Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ******************************************************************************
export CC=
export CXX=
intel=$1
THIS_DIR=$(cd $(dirname $0); pwd)

GREEN='\033[032m'
NORM='\033[0m'
RED='\033[031m'

#Select Compiler and Find MKL support
if [[ `uname` == 'Linux' ]]; then
    ICC_ON=0
    if [[ $intel == 'intel' ]]; then
        if [[ `which icc` == '' ]]; then
            CC=gcc
        else
            CC=icc
        fi
        if [[ `echo $CC | grep icc` != '' ]]; then
            ICC_ON=1
        fi
    else
        ICC_ON=0
        CC=gcc
    fi

    if [[ $ICC_ON == 1 ]]; then
       echo -e "using ${GREEN}Intel compiler ${NORM}..."
    else
       echo -e "using ${GREEN}GNU compiler${NORM}..."
    fi


    RETURN_STRING=`./prepare_mkl.sh $ICC_ON`
    export MKLROOT=`echo $RETURN_STRING | awk -F "=" '{print $2}' | awk '{print $1}'`
    echo -e "mkl root: ${GREEN}$MKLROOT${NORM}"
    export LD_LIBRARY_PATH=$MKLROOT/lib:$LD_LIBRARY_PATH
    export LIBRARY_PATH=$MKLROOT/lib:$LIBRARY_PATH
    export CPATH=$MKLROOT/include:$CPATH
    #build neon mklEngine
    MKL_ENGINE_PATH='neon/backends/mklEngine'
    cd $MKL_ENGINE_PATH && make clean && make
    cd $THIS_DIR

elif [[ `uname` == 'Darwin' ]]; then
    echo -e "Mac detected"
    RETURN_STRING=`./prepare_mkl.sh 2`
    export MKLROOT=`echo $RETURN_STRING | awk -F "=" '{print $2}' | awk '{print $1}'`
    echo -e "mkl root: ${GREEN}$MKLROOT${NORM}"
    export LD_LIBRARY_PATH=$MKLROOT/lib:$LD_LIBRARY_PATH
    export LIBRARY_PATH=$MKLROOT/lib:$LIBRARY_PATH
    export CPATH=$MKLROOT/include:$CPATH
    #build neon mklEngine
    MKL_ENGINE_PATH='neon/backends/mklEngine'
    export DYLD_LIBRARY_PATH=$MKLROOT/lib:$THIS_DIR/$MKL_ENGINE_PATH:$DYLD_LIBRARY_PATH
    export MAC_BUILD=1
    cd $MKL_ENGINE_PATH && make clean && make
    cp ${MKLROOT}/lib/*.dylib .
    cd $THIS_DIR

elif [[ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" || "$(expr substr $(uname -s) 1 7)" == "MSYS_NT" ]]; then
    echo -e "Windows detected"
    #build neon mklEngine
    MKL_ENGINE_PATH='neon/backends/mklEngine'
    cd $MKL_ENGINE_PATH && make clean && ./make_msys64.bat
    cd $THIS_DIR

else
    echo -e "Environment not supported, skipping MKL install"
fi
