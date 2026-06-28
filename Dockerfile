# Start with an official ROS 2 base image for the desired distribution
FROM ros:humble-ros-base AS mujoco_base

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    ROS_DISTRO=humble

ARG USER_UID=1001
ARG USER_GID=1001
ARG USERNAME=user
ARG MUJOCO_VERSION=3.2.6

ENV MUJOCO_VERSION=${MUJOCO_VERSION}

# Install essential packages and ROS development tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash-completion \
        curl \
        gdb \
        git \
        nano \
        tree \
        openssh-client \
        python3-venv \
        python3-colcon-argcomplete \
        python3-colcon-common-extensions \
        sudo \
        vim \
        libglfw3-dev \
        wget \
        ripgrep \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Setup user configuration
RUN if ! getent group "$USER_GID" > /dev/null; then groupadd --gid "$USER_GID" "$USERNAME"; fi \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && echo "source /opt/ros/$ROS_DISTRO/setup.bash" >> /home/$USERNAME/.bashrc \
    && echo "source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash" >> /home/$USERNAME/.bashrc

USER $USERNAME

# Install MuJoCo
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
        amd64) mujoco_arch="linux-x86_64" ;; \
        arm64) mujoco_arch="linux-aarch64" ;; \
        *) echo "Unsupported architecture for MuJoCo: $arch" >&2; exit 1 ;; \
    esac; \
    wget "https://github.com/google-deepmind/mujoco/releases/download/${MUJOCO_VERSION}/mujoco-${MUJOCO_VERSION}-${mujoco_arch}.tar.gz" -O "$HOME/mujoco-${MUJOCO_VERSION}.tar.gz"; \
    tar -xzf "$HOME/mujoco-${MUJOCO_VERSION}.tar.gz" -C "$HOME"; \
    rm "$HOME/mujoco-${MUJOCO_VERSION}.tar.gz"

FROM mujoco_base AS crisp_dev

ARG USER_UID=1001
ARG USER_GID=1001
ARG USERNAME=user

# Use OSRF's Gazebo packages for Ignition Fortress dependency versions
# (Hack fix for ARM64 builds)
RUN set -eux; \
    curl -fsSL https://packages.osrfoundation.org/gazebo.gpg -o /tmp/gazebo.gpg; \
    sudo install -D -m 0644 /tmp/gazebo.gpg /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg; \
    rm /tmp/gazebo.gpg; \
    . /etc/os-release; \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable ${VERSION_CODENAME} main" \
        | sudo tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null

# Install some ROS 2 dependencies to create a cache layer
RUN sudo apt-get update \
    && sudo apt-get install -y --no-install-recommends \
        ros-humble-ros-gz \
        ros-humble-sdformat-urdf \
        ros-humble-joint-state-publisher-gui \
        ros-humble-ros2controlcli \
        ros-humble-controller-interface \
        ros-humble-hardware-interface-testing \
        ros-humble-ament-cmake-clang-format \
        ros-humble-ament-cmake-clang-tidy \
        ros-humble-controller-manager \
        ros-humble-ros2-control-test-assets \
        libignition-gazebo6-dev \
        libignition-plugin-dev \
        ros-humble-hardware-interface \
        ros-humble-control-msgs \
        ros-humble-backward-ros \
        ros-humble-generate-parameter-library \
        ros-humble-realtime-tools \
        ros-humble-joint-state-publisher \
        ros-humble-joint-state-broadcaster \
        ros-humble-moveit-ros-move-group \
        ros-humble-moveit-kinematics \
        ros-humble-moveit-planners-ompl \
        ros-humble-moveit-ros-visualization \
        ros-humble-joint-trajectory-controller \
        ros-humble-moveit-simple-controller-manager \
        ros-humble-rviz2 \
        ros-humble-xacro \
        ros-humble-teleop-twist-keyboard \
        ros-humble-joy \
        ros-humble-teleop-twist-joy \
        ros-humble-foxglove-bridge \
        ros-humble-rmw-cyclonedds-cpp \
    && sudo apt-get clean \
    && sudo rm -rf /var/lib/apt/lists/*

WORKDIR /ros2_ws

# Install the missing ROS 2 dependencies
COPY --chown=$USER_UID:$USER_GID . /ros2_ws
RUN mkdir -p /ros2_ws/src \
    && sudo chown -R $USER_UID:$USER_GID /ros2_ws \
    && git submodule update --init --recursive \
    && sudo apt-get update \
    && rosdep update \
    && rosdep install --from-paths src --ignore-src --rosdistro $ROS_DISTRO -y \
    && sudo apt-get clean \
    && sudo rm -rf /var/lib/apt/lists/* \
    && rm -rf /home/$USERNAME/.ros

# Set the default shell to bash and the workdir to the source directory
SHELL [ "/bin/bash", "-c" ]
CMD [ "bash" ]
