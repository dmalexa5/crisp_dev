## Test MoveIt for franka
ros2 launch franka_bringup franka.launch.py robot_type:=fr3 robot_ip:=192.168.1.15 load_gripper:=true

ros2 launch franka_fr3_moveit_config moveit.launch.py robot_ip:=192.168.1.15 load_gripper:=true

## Build crisp controllers
export MAKEFLAGS="-j2"
colcon build --packages-select crisp_controllers --symlink-install --parallel-workers 1

## Test signal 
python3 /tmp/ping.py

## Steps to install Gello 
Steps

1. On the host: copy the GELLO package into the mounted workspace.
#    A symlink won't work, because gello_software isn't mounted in the container.
cp -r ~/ros2_ws/gello_software/ros2/src/franka_gello_state_publisher ~/ros2_ws/crisp_dev/src/

2. Open a shell in the container
docker exec -it crisp_dev bash

3. Install the missing Python packages
pip install dynamixel_sdk tyro

4. Build only this package, so the crisp/franka build is left alone
cd /ros2_ws
colcon build --symlink-install --packages-select franka_gello_state_publisher
source install/setup.bash

5. Launch
ros2 launch franka_gello_state_publisher main.launch.py config_file:=franka_gello_duo.yaml

Before step 4, set com_port in /ros2_ws/src/franka_gello_state_publisher/config/franka_gello_duo.yaml. Then check it with ros2 topic echo /gello/joint_states, either on the host or in a second docker exec shell.

### Steps to Teleop with GELLO
1. Publish gello joint state
```
ros2 launch franka_gello_state_publisher main.launch.py config_file:=franka_gello_duo.yaml
```

2. Launch joint impedance controller
Activate FCI and launch controller
```
ros2 launch franka_fr3_arm_controllers franka_fr3_arm_controllers.launch.py robot_config_file:=fr3_config_duo.yaml
```

3. Launch gripper controller
```
ros2 launch franka_gripper_manager franka_gripper_client.launch.py config_file:=fr3_config_franka_hand_duo.yaml
```

### Setup teleop with 