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
If you need to run docker with root rights run it via `sudo`.
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
    -v ~/.Xauthority:/root/.Xauthority:ro \
    -v /dev/dri:/dev/dri:ro \
    -v /dev/shm:/dev/shm \
    --shm-size=512M docker-image-name /usr/local/matlab/bin/matlab

# Data processing steps

## Initialization

After starting up the MATLAB you need to add directories with compiled OpenCV and contrib plugins along with the PTV package to MATLAB PATH environment variable

    addpath(ptv, opencv, opencv_contrib)

In general case you need to do 3 processes

1. System calibration
2. Left and right video delay detection
3. Tracking

## System calibration

If you start work from scratch or you made changes to your camera system you need calibrate your camera system (to get rid of lens distortion, basically to make rectangular objects look rectangular on the video).
Also you need calibration in case of any significant change of stereo camera system: resolution, lenses, lens housing, camera-to-camera distance change or camera replacement (to other camera or swap cameras between left and ight positions).
Otherwise you don't need to do it on each dataset and old calibration config can be used.

For calibration you will need to determine the time lag between left and right videos, see below.

### Calibration frames extraction

1. Play video from left camera in video player
2. Pick the frame where calibration pattern (chequerbord) is visible without glares and is not moving
3. Write time of the frame
4. Repeat from step 2

After that convert recorded times into seconds from video start, in example below these times recorded into array timestamps

    timestamps = [21 26 32]
    PTV.extractCalibrationFrames('left_camera_calibration_video.mp4', 'left_camera_calibration_video.mp4', timestamps, 'lag.mat', mexopencvPath, 'calibration_frames')

### Calibration

    obj = PTV.calibration("./calibration_frames", 30)

## Delay detection

    lag = PTV.syncVideos('left_camera_videos/', 'right_camera_videos/', mexopencvPath, 'videoFileExtension', 'mp4', 'audioWindowSize', 48e3*5)
    lag.save('lag')

## Tracking


