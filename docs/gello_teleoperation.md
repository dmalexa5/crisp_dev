# GELLO Implementation for Franka FR3 with ROS 2 (Humble) 

This document describes how to use GELLO with crisp_dev docker container.

## Calibration

Follow the [official GELLO guide](https://github.com/wuphilipp/gello_software/tree/main/ros2) to calibrate GELLO.
There are 3 config files need to customize for dual-arm system:
- GELLO joint_state publisher: `src/franka_gello/franka_gello_state_publisher/config/franka_gello_duo.yaml`
- Franka joint_follower (joint impedance) controller: `src/franka_gello/franka_fr3_arm_controllers/config/fr3_config_duo.yaml`
- Franka gripper follower controller: `src/franka_gello/franka_gripper_manager/config/fr3_config_franka_hand_duo.yaml`

## Start teleoperation with GELLO dual-arm

Before activate teleoperation, bring 2 gello arms to ready configuration then follow the steps in different terminals inside docker:

1. Publish gello joint state
```
ros2 launch franka_gello_state_publisher main.launch.py config_file:=franka_gello_duo.yaml
```

2. Launch joint impedance follower controller
Activate FCI and launch controller
```
ros2 launch franka_fr3_arm_controllers franka_fr3_arm_controllers.launch.py robot_config_file:=fr3_config_duo.yaml
```

3. Launch gripper controller
```
ros2 launch franka_gripper_manager franka_gripper_client.launch.py config_file:=fr3_config_franka_hand_duo.yaml
```