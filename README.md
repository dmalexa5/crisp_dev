## Setup

You must have **docker engine** installed, **_not_** docker desktop. This will interfere with the container inheriting the `PREEMPT_RT` kernel neccessary to drive franka manipulators.

  1. **Save the current user id into a file:**
      ```bash
      echo -e "USER_UID=$(id -u $USER)\nUSER_GID=$(id -g $USER)" > .env
      ```
      It is needed to mount the folder from inside the Docker container.

  2. **Build the container:**
      ```bash
      docker compose build
      ```
  3. **Run the container:**
      ```bash
      docker compose up -d
      ```
  4. **Open a shell inside the container:**
      ```bash
      docker exec -it crisp_contact_decomposition /bin/bash
      ```
      or
      `Ctrl + Shift + P` > `Dev Containers: Attach to Running Container`
  5. **Clone the latests dependencies:**
      ```bash
      cd /ros2_ws && mkdir src
      vcs import src < dependency.repos --recursive --skip-existing
      ```
  6. **Update bashrc aliases (optional)**
      ```bash
      echo 'alias cb="colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release -DCMAKE_EXPORT_COMPILE_COMMANDS=ON"' >> ~/.bashrc
      echo 'alias cdb="colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON"' >> ~/.bashrc
      echo 'alias s="source install/setup.bash"' >> ~/.bashrc
      ```
  7. **Build the workspace:**

      ```bash
      colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
      ```
      or, if you set up aliases, `cb`

> ![NOTE]
> This project is in rapid development. Warnings are expected, especially during the first build.

  7. **Source the built workspace:**
      ```bash
      source install/setup.bash
      ```
      or `s`


## Python environement setup

This package is set up to install `crisp_py` as an editable python package into a virtual environment that has access to system site packages.

  1. **Activate the virtual environment:**
      ```bash
      source /ros2_ws/.venv/bin/activate
      ```
  2. **Install crisp_py:**
      ```bash
      cd /ros2_ws/src/crisp_py/
      pip install -e .
      ```

## Run Examples

### Franka arm operational space control
This demonstration is a direct application of the CRISP OSC controller and a good starting point for verifying everything works correctly.

  1. **Ensure FCI is enabled**
      We recommend running the `communication_test` before running the example for the first time.
      
      ```bash
      communication_test <robot-ip>
      ```

  2. **Start the controllers**
      In a seperate terminal, start the CRISP cartesian controller and franka gripper node
      ```bash
      cd /ros2_ws/ && source install/setup.bash
      export ROBOT_IP=<your robot ip address>
      ros2 launch contact_decomp_demos franka.launch.py robot_ip:=$ROBOT_IP & ros2 launch franka_gripper gripper.launch.py robot_ip:=$ROBOT_IP
      ```
      In the future, these will likely be launched from the same file.
    
  3. **Run the operational space control demo**
      In the original terminal (with .venv activated), run the demo.
      ```bash
      cd /ros2_ws/src/contact_decomp_demos/examples/
      python3 01_figure_eight_osc.py
      ```
[def]: #docker-container-installation
