FROM nvidia/cuda:8.0-devel-ubuntu16.04
# Forked from https://github.com/crisbal/docker-torch-rnn/blob/master/CUDA/8.0/Dockerfile
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

# Required packages
RUN apt-get update && apt-get install --no-install-recommends -y \
    python \
    build-essential \
    python2.7-dev \
    python-pip \
    git \
    sudo \
    libhdf5-dev \
    cython \
    software-properties-common && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# We force git over https so we avoid port blocked on some build systems
RUN git config --global url."https://".insteadOf git://

# Torch and luarocks
RUN git clone https://github.com/torch/distro.git /root/torch --recursive && cd /root/torch && \
    bash install-deps && \
    ./install.sh -b

ENV LUA_PATH='/root/.luarocks/share/lua/5.1/?.lua;/root/.luarocks/share/lua/5.1/?/init.lua;/root/torch/install/share/lua/5.1/?.lua;/root/torch/install/share/lua/5.1/?/init.lua;./?.lua;/root/torch/install/share/luajit-2.1.0-beta1/?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua'
ENV LUA_CPATH='/root/.luarocks/lib/lua/5.1/?.so;/root/torch/install/lib/lua/5.1/?.so;./?.so;/usr/local/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/loadall.so'
ENV PATH=/root/torch/install/bin:$PATH
ENV LD_LIBRARY_PATH=/root/torch/install/lib:$LD_LIBRARY_PATH
ENV DYLD_LIBRARY_PATH=/root/torch/install/lib:$DYLD_LIBRARY_PATH
ENV LUA_CPATH='/root/torch/install/lib/?.so;'$LUA_CPATH


#Lua requirements
WORKDIR /root
RUN luarocks install torch && \
    luarocks install nn && \
    luarocks install optim && \
    luarocks install lua-cjson


WORKDIR /root/torch-hdf5
RUN git clone https://github.com/deepmind/torch-hdf5 . && luarocks make hdf5-0-0.rockspec

#CUDA
WORKDIR /root
RUN luarocks install cutorch && \
    luarocks install cunn

#torch-rnn and python requirements
RUN pip install --upgrade pip
RUN pip install -U setuptools

# we use https://github.com/jcjohnson/torch-rnn/blob/master/requirements.txt as a quideline
RUN pip install Cython==0.23.4
RUN pip install numpy==1.10.4
RUN pip install argparse==1.2.1
RUN HDF5_DIR=/usr/lib/x86_64-linux-gnu/hdf5/serial/ pip install h5py==2.5.0
RUN pip install six==1.10.0
RUN git clone https://github.com/jcjohnson/torch-rnn

#Done!
WORKDIR /root/torch-rnn