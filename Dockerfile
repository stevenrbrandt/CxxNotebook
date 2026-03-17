FROM fedora
RUN dnf install -y gcc-c++ gcc make git \
    bzip2 hwloc-devel blas blas-devel lapack lapack-devel boost-devel \
    libatomic which vim-enhanced wget zlib-devel cmake \
    python3-flake8 gdb sudo python3 python3-pip openmpi-devel sqlite-devel sqlite \
    findutils openssl-devel papi papi-devel lm_sensors-devel tbb-devel \
    xz bzip2 patch flex openssh-server \
    texlive-xetex texlive-bibtex texlive-adjustbox texlive-caption texlive-collectbox \
    texlive-enumitem texlive-environ texlive-eurosym texlive-jknapltx texlive-parskip \
    texlive-pgf texlive-rsfs texlive-tcolorbox texlive-titling texlive-trimspaces \
    texlive-ucs texlive-ulem texlive-upquote texlive-latex pandoc ImageMagick \
    root python3-root root-notebook python3-devel root-graf-gpadv7 

WORKDIR /

RUN dnf install -y python3-devel

RUN git clone --depth 1 https://github.com/pybind/pybind11.git && \
    mkdir -p /pybind11/build && \
    cd /pybind11/build && \
    cmake -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DPYBIND11_PYTHON_VERSION=${PYVER} .. && \
    make -j ${CPUS} install && \
    rm -f $(find . -name \*.o)

RUN git clone --depth 1 https://bitbucket.org/blaze-lib/blaze.git && \
    cd /blaze && \
    mkdir -p /blaze/build && \
    cd /blaze/build && \
    cmake -DCMAKE_BUILD_TYPE=${BUILD_TYPE} .. && \
    make -j ${CPUS} install && \
    rm -f $(find . -name \*.o)

RUN git clone --depth 1 https://github.com/STEllAR-GROUP/blaze_tensor.git && \
    mkdir -p /blaze_tensor/build && \
    cd /blaze_tensor/build && \
    cmake -DCMAKE_BUILD_TYPE=${BUILD_TYPE} .. && \
    make -j ${CPUS} install && \
    rm -f $(find . -name \*.o)

RUN useradd -m jovyan -s /bin/bash
USER jovyan
WORKDIR /home/jovyan
USER root
RUN pip3 install --upgrade pip
RUN pip3 install jupyter matplotlib numpy termcolor 
#oauthenticator==15.1.0 jupyterhub==4.1.5

#RUN dnf install -y npm
#RUN npm install -g configurable-http-proxy 

RUN git clone --branch hpsf_2026 --depth 1 https://github.com/STEllAR-GROUP/hpx.git /hpx
WORKDIR /hpx
RUN mkdir -p /hpx/build
WORKDIR /hpx/build
RUN cmake -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
      -DHPX_FILESYSTEM_WITH_BOOST_FILESYSTEM_COMPATIBILITY=ON \
      -DHPX_WITH_CXX17_HARDWARE_DESTRUCTIVE_INTERFERENCE_SIZE=OFF \
      -DHPX_WITH_FETCH_ASIO=ON \
      -DHPX_WITH_BUILTIN_INTEGER_PACK=OFF \
      -DHPX_WITH_ITTNOTIFY=OFF \
      -DHPX_WITH_THREAD_COMPATIBILITY=ON \
      -DHPX_WITH_MALLOC=system \
      -DHPX_WITH_MORE_THAN_64_THREADS=ON \
      -DHPX_WITH_MAX_CPU_COUNT=80 \
      -DHPX_WITH_EXAMPLES=Off \
      -DHPX_WITH_CXX_STANDARD=20 \
      -DHPX_WITH_DATAPAR_BACKEND=STD_EXPERIMENTAL_SIMD \
      .. && \
    make -j ${CPUS} install && \
    rm -f $(find . -name \*.o)

WORKDIR /
RUN git clone --depth 1 https://github.com/STEllAR-GROUP/BlazeIterative.git
WORKDIR /BlazeIterative/build
RUN cmake ..
RUN make install

WORKDIR /notebooks
COPY ./binder/start ./start

WORKDIR /root
RUN chmod 755 .

RUN mkdir -p /etc/skel/

COPY notebooks/*.ipynb /etc/skel/
RUN jupyter nbconvert --clear-output --inplace /etc/skel/*.ipynb

RUN perl -p -i -e 's/Boost::/boost_/g' /usr/local/lib64/pkgconfig/*.pc
RUN pip3 install jupyterlab

USER jovyan
WORKDIR /home/jovyan
RUN cp /etc/skel/*.ipynb .
ENV HOME=/home/jovyan
ENV PORT=8888
