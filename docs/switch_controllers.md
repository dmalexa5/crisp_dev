In every new terminal inside the container:

```bash
/bin/bash && cd /ros2_ws
source scripts/ros_env.sh
```

Launch dual Franka:

```bash
ros2 launch crisp_controllers_robot_demos dual_franka.launch.py \
  use_fake_hardware:=false \
  left_robot_ip:=192.168.1.15 \
  right_robot_ip:=192.168.1.11
```

After launch finishes spawning controllers, verify state:

```bash
ros2 control list_controllers -c /left/controller_manager
ros2 control list_controllers -c /right/controller_manager
```

Switch from joint trajectory to Cartesian impedance controller:

```bash
ros2 control switch_controllers \
  --controller-manager /left/controller_manager \
  --deactivate joint_trajectory_controller \
  --activate cartesian_impedance_controller \
  --strict

ros2 control switch_controllers \
  --controller-manager /right/controller_manager \
  --deactivate joint_trajectory_controller \
  --activate cartesian_impedance_controller \
  --strict
```

Activate the wrench broadcaster:

```bash
ros2 control switch_controllers \
  --controller-manager /left/controller_manager \
  --activate wrench_broadcaster \
  --strict

ros2 control switch_controllers \
  --controller-manager /right/controller_manager \
  --activate wrench_broadcaster \
  --strict
```

View wrench output:

```bash
ros2 topic echo /left/external_wrench
```

In another terminal:

```bash
ros2 topic echo /right/external_wrench
```

Optional sanity checks:

```bash
ros2 topic hz /left/external_wrench
ros2 topic hz /right/external_wrench
```