On host machine you will need MATLAB with several toolboxes along with toolkit for access to GPU from Docker (package requires GUI to run correctly) or you can check how to install matlab inside docker as it shown [here](https://github.com/mathworks-ref-arch/matlab-dockerfile) and you can take a look on [Dockerfile code](https://github.com/mathworks-ref-arch/container-images/) by Mathworks.
List of MATLAB toolboxes (not all might be required though):

    product.Bioinformatics_Toolbox
    product.Computer_Vision_Toolbox
    product.Financial_Toolbox
    product.Image_Processing_Toolbox
    product.MATLAB
    product.MATLAB_Parallel_Server
    product.Optimization_Toolbox
    product.Parallel_Computing_Toolbox
    product.Signal_Processing_Toolbox
    product.Statistics_and_Machine_Learning_Toolbox

Build an image with

    $ docker build -t matlab-ptv

You might need superuser rights to run docker, also you can check rootless mode.
To run MATLAB in Docker container with GUI you need to run it as follows (see [original answer](https://www.mathworks.com/matlabcentral/answers/332224-is-it-possible-to-install-matlab-in-a-docker-image)):

    $ xhost +
    $ docker run --gpus all -it --rm \
    -e DISPLAY=$DISPLAY \
    -e XAUTHORITY=$XAUTHORITY \
    -e LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 \
    -e MESA_LOADER_DRIVER_OVERRIDE=i965 \
    -e LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 \
    -e LD_LIBRARY_PATH=/usr/lib/xorg/modules/dri/ \
    -e MATLAB_JAVA=/usr/lib/jvm/java-8-openjdk-amd64/jre \
    -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
    -v /home/volkov/.Xauthority:/root/.Xauthority:ro \
    -v /dev/dri:/dev/dri:ro \
    -v /dev/shm:/dev/shm \
    --shm-size=512M docker-image-name
