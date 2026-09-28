## Test MoveIt for franka
ros2 launch franka_bringup franka.launch.py robot_type:=fr3 robot_ip:=192.168.1.15 load_gripper:=true

ros2 launch franka_fr3_moveit_config moveit.launch.py robot_ip:=192.168.1.15 load_gripper:=true

## Build crisp controllers
export MAKEFLAGS="-j2"
colcon build --packages-select crisp_controllers --symlink-install --parallel-workers 1

