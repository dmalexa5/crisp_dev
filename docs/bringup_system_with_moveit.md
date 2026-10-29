# ROS 2 Environment Setup and Franka Duo Bringup

## 1. Build ROS 2 Environment

Activate the Docker container and source the ROS 2 environment:

```bash
source scripts/ros_env.sh
```

### 1.1. Build `crisp_controllers` First

Build the computationally intensive `crisp_controllers` package separately before building the entire workspace.

```bash
export MAKEFLAGS="-j2"

colcon build \
    --packages-select crisp_controllers \
    --symlink-install \
    --parallel-workers 1
```

### 1.2. Build the Entire Workspace

After successfully building `crisp_controllers`, build the remaining workspace packages.

## 2. Test Default MoveIt Configuration for Franka FR3

Before bringing up the dual-arm system, verify the default MoveIt configuration using a single Franka FR3 robot.

### 2.1. Launch the Franka Robot

```bash
ros2 launch franka_bringup franka.launch.py \
    robot_type:=fr3 \
    robot_ip:=192.168.1.15 \
    load_gripper:=true
```

### 2.2. Launch MoveIt

In another terminal with the ROS 2 environment sourced, run:

```bash
ros2 launch franka_fr3_moveit_config moveit.launch.py \
    robot_ip:=192.168.1.15 \
    load_gripper:=true
```

## 3. Bring Up the Prismatic Franka Duo System

### 3.1. System Architecture

The dual-computer architecture separates real-time robot control from high-level planning and perception.

**Real-time computer**
- Runs the ROS 2 low-level controllers.
- Runs the robot state broadcasters.
- Communicates with both Franka arms.
- Executes real-time control tasks.

**Workstation computer**
- Monitors system state.
- Visualizes the digital twin.
- Processes perception signals.
- Publishes high-level planning results and commands.

### 3.2. Network and ROS 2 Configuration

The two computers communicate over Ethernet using ROS 2 with the Cyclone DDS middleware.

Both computers must:
- Use the same `ROS_DOMAIN_ID`.
- Configure Cyclone DDS consistently for Ethernet-based ROS 2 communication.
- Synchronize their system clocks using Chrony.

Follow [`docs/synchronize_ubuntu_computers.md`](synchronize_ubuntu_computers.md) for clock synchronization setup.

## 4. Bring Up the System on the Real-Time Computer

### 4.1. Prepare the Robots

1. Activate FCI mode for both Franka arms through Franka Desk.
2. Activate the Docker container on the real-time computer.
3. Source the ROS 2 environment and configure the ROS 2 network settings.

```bash
source scripts/ros_env.sh
```

Ensure that `ROS_DOMAIN_ID` and Cyclone DDS are configured correctly for the Ethernet network.

### 4.2. Launch the Dual-Arm System

Launch the dual-arm hardware bringup:

```bash
ros2 launch prismatic_fr3_duo_moveit_config real_hardware.launch.py
```

### 4.3. Activate the Desired Controllers

Activate the required controllers according to [`docs/bringup_system_with_moveit.md`](bringup_system_with_moveit.md).

## 5. Bring Up the System on the Workstation Computer

### 5.1. Prepare the Environment

1. Activate the Docker container on the workstation.
2. Configure the same `ROS_DOMAIN_ID` used by the real-time computer.
3. Configure Cyclone DDS to communicate over Ethernet.
4. Source the ROS 2 environment.

```bash
source scripts/ros_env.sh
```

### 5.2. Launch MoveIt and RViz

Launch MoveIt on the workstation to visualize and monitor the dual-arm digital twin:

```bash
ros2 launch prismatic_fr3_duo_moveit_config moveit_workstation.launch.py
```

The workstation provides the visualization and high-level planning interface while the real-time computer handles low-level robot control.

## 6. Bringup Checklist

Before operating the dual-arm system, verify the following:

- [ ] Both Franka arms are in FCI mode.
- [ ] The Docker environment is running on both computers.
- [ ] The ROS 2 environment has been sourced on both computers.
- [ ] Both computers use the same `ROS_DOMAIN_ID`.
- [ ] Cyclone DDS is configured for Ethernet communication.
- [ ] Chrony clock synchronization is configured.
- [ ] The dual-arm hardware bringup launches successfully on the real-time computer.
- [ ] The desired ROS 2 controllers are activated.
- [ ] MoveIt and RViz launch successfully on the workstation.
- [ ] The workstation receives robot state updates from both arms.