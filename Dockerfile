FROM ubuntu:20.04

ENV DEBIAN_FRONTEND="noninteractive" TZ="UTC"

RUN apt-get update
#Install dependencies for MATLAB
RUN apt-get install --no-install-recommends -y ca-certificates libasound2 libatk1.0-0 libc6 libcairo-gobject2 libcairo2 \
  libcrypt1 libcups2 libdbus-1-3 libfontconfig1 libgdk-pixbuf2.0-0 libgstreamer-plugins-base1.0-0 libgstreamer1.0-0 \
  libgtk-3-0 libnspr4 libnss3 libpam0g libpango-1.0-0 libpangocairo-1.0-0 libpangoft2-1.0-0 libpython2.7 libpython3.8 \
  libselinux1 libsm6 libsndfile1 libtcl8.6 libuuid1 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 \
  libxext6 libxfixes3 libxft2 libxi6 libxinerama1 libxrandr2 libxrender1 libxt6 libxtst6 libxxf86vm1 locales locales-all \
  procps sudo unzip wget xkb-data zlib1g
#Install all the codecs for different media files
RUN apt-get install --no-install-recommends -y libgstreamer1.0-0 \
  gstreamer1.0-tools \
  gstreamer1.0-libav \
  gstreamer1.0-plugins-base \
  gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-bad \
  gstreamer1.0-plugins-ugly
#Install mesa for hardware rendering of OpenGL
RUN apt-get install -y --no-install-recommends libglu1-mesa-dev

#Build dependencies for OpenCV
RUN apt-get install --no-install-recommends -y build-essential cmake pkg-config git
RUN apt-get install --no-install-recommends -y zlib1g-dev libjpeg-dev libpng-dev libtiff-dev libopenexr-dev
RUN apt-get install --no-install-recommends -y libavcodec-dev libavformat-dev libswscale-dev
RUN apt-get install --no-install-recommends -y libv4l-dev libdc1394-22-dev libxine2-dev libgphoto2-dev
RUN apt-get install --no-install-recommends -y libgtk2.0-dev libtbb-dev libeigen3-dev libblas-dev liblapack-dev liblapacke-dev libatlas-base-dev

#For compiling MEX files
RUN apt-get install -y gcc g++ gfortran
RUN apt-get install -y libstdc++6 openjdk-8-jre-headless
RUN apt-get clean
RUN apt-get -y autoremove
RUN rm -rf /var/lib/apt/lists/*

#OpenCV compiling
#Retrieving sources
RUN mkdir ~/cv
RUN cd ~/cv && wget -O opencv-3.4.1.zip https://github.com/opencv/opencv/archive/3.4.1.zip
RUN cd ~/cv && wget -O opencv_contrib-3.4.1.zip https://github.com/opencv/opencv_contrib/archive/3.4.1.zip
RUN cd ~/cv && unzip opencv-3.4.1.zip
RUN cd ~/cv && unzip opencv_contrib-3.4.1.zip

#Build and install
RUN mkdir ~/cv/build
RUN cd ~/cv/build && cmake -G "Unix Makefiles" \
    -DBUILD_DOCS=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_PERF_TESTS=OFF \
    -DBUILD_TESTS=OFF \
    -DBUILD_JAVA=OFF \
    -DWITH_CUDA=OFF \
    -DWITH_CUBLAS=OFF \
    -DWITH_CUFFT=OFF \
    -DWITH_NVCUVID=OFF \
    -DWITH_MATLAB=OFF \
    -DBUILD_opencv_cudaarithm=OFF \
    -DBUILD_opencv_cudabgsegm=OFF \
    -DBUILD_opencv_cudacodec=OFF \
    -DBUILD_opencv_cudafeatures2d=OFF \
    -DBUILD_opencv_cudafilters=OFF \
    -DBUILD_opencv_cudaimgproc=OFF \
    -DBUILD_opencv_cudalegacy=OFF \
    -DBUILD_opencv_cudaobjdetect=OFF \
    -DBUILD_opencv_cudaoptflow=OFF \
    -DBUILD_opencv_cudastereo=OFF \
    -DBUILD_opencv_cudawarping=OFF \
    -DBUILD_opencv_cudev=OFF \
    -DBUILD_opencv_java=OFF \
    -DBUILD_opencv_java_bindings_generator=OFF \
    -DBUILD_opencv_js=OFF \
    -DBUILD_opencv_python2=OFF \
    -DBUILD_opencv_python3=OFF \
    -DBUILD_opencv_python_bindings_generator=OFF \
    -DBUILD_opencv_ts=OFF \
    -DBUILD_opencv_world=OFF \
    -DBUILD_opencv_matlab=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DOPENCV_ENABLE_NONFREE=ON \
    -DOPENCV_EXTRA_MODULES_PATH=~/cv/opencv_contrib-3.4.1/modules ~/cv/opencv-3.4.1
RUN cd ~/cv/build && make -j$(nproc)
RUN cd ~/cv/build && make install
RUN sh -c 'echo "/usr/local/lib" > /etc/ld.so.conf.d/opencv3.conf'
RUN ldconfig
RUN export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH

#Copy matlab installation into the container (required to compile MEX files)
#This way docker make a copy of matlab intallation on the host system
COPY matlab /usr/local/matlab
#The other option is to install over the internet (not tested, check Mathworks docker files for the reference)

#Building mexopencv
RUN cd ~/cv && wget -O mexopencv-master.zip https://github.com/kyamagu/mexopencv/archive/master.zip
RUN cd ~/cv && unzip mexopencv-master.zip && mv mexopencv-master mexopencv
RUN cd ~/cv/mexopencv && make -j$(nproc) MATLABDIR=/usr/local/matlab WITH_CONTRIB=true all contrib

#Fetching PTV package source code, using my version with bug fixes
RUN mkdir matlab-ptv
RUN git clone https://github.com/taranarmo/matlab-particle-tracking-stereo-camera-setup.git matlab-ptv/ --depth=1
