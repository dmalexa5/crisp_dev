# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Scope and conventions

`AGENTS.md` at the repo root holds the working rules for this workspace (real-time safety in
`update()`, hardware-safety limits on what commands may be run, `ros2_control` plugin checklist,
editing discipline). **Read it and follow it** — the rules below are additive, not a replacement.

Two rules are worth restating because they are easy to violate accidentally:

- Never run anything that can move the robot, activate a real controller, command effort, or
  connect to the Franka FCI unless explicitly told to.
- Do not create, build, or run tests unless explicitly requested.

## Where the code actually runs

This is a ROS 2 **Humble** workspace intended to be built and run **inside the `crisp_dev` Docker
container**, not on the host. The repo root is bind-mounted to `/ros2_ws` in the container, so host
paths and container paths refer to the same files but the container is the only place where
`/opt/ros/humble` and the ROS dependencies exist. The container is `privileged`, `network_mode:
host`, with `rtprio: 99` — it inherits the host `PREEMPT_RT` kernel, which is why Docker Desktop
must not be used.

```bash
docker compose build          # .env must contain USER_UID/USER_GID (see README.md step 1)
docker compose up -d
docker exec -it crisp_dev /bin/bash
```

Inside the container, every new shell needs the environment sourced:

```bash
source /ros2_ws/scripts/ros_env.sh   # sources ROS + install/, sets ROS_DOMAIN_ID=42, cyclonedds
```

## Build and test

```bash
# From /ros2_ws inside the container. Release is the CMake default.
colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
colcon build --packages-select crisp_controllers          # iterate on one package
```

`BUILD_TESTING` gates the gtests in `crisp_controllers`. The `cb`/`cdb` aliases suggested in
`README.md` pass `-DBUILD_TESTING=OFF`, so tests will not exist unless you build without that flag.

```bash
colcon build --packages-select crisp_controllers --cmake-args -DBUILD_TESTING=ON
colcon test --packages-select crisp_controllers
colcon test --packages-select crisp_controllers --ctest-args -R test_pseudo_inverse  # single test
colcon test-result --verbose
```

Tests cover only the header-only math utilities (`tests/test_pseudo_inverse.cpp`,
`test_torque_rate_saturation.cpp`, `test_filters.cpp`). There is no test harness for the controller
lifecycle itself.

`build/`, `install/`, and `log/` are generated artifacts and are gitignored.

## Repository layout

Everything under `src/` is a **git submodule**, including the two packages that are actually
developed here (`crisp_controllers`, `crisp_controllers_demos`, both tracking their `devel`
branches). Changes to those must be committed in the submodule first, then the new pointer
committed in the superproject. `franka_ros2`, `franka_description`, `libfranka`, and
`olvx_descriptions_module` are vendored dependencies — treat them as read-only unless asked.

| Path | Role |
| --- | --- |
| `src/crisp_controllers` | The C++ `ros2_control` controller plugin library. The main deliverable. |
| `src/crisp_controllers_demos` | Contains the ROS package `crisp_controllers_robot_demos`: launch files, URDF xacros, and controller YAML for FR3 / dual-FR3 / IIWA / Kinova. Note the directory name and the package name differ. |
| `src/franka_ros2` | Franka driver; provides `franka_hardware/FrankaHardwareInterface` and `franka_gripper`. |
| `docs/switch_controllers.md` | Worked example of bringing up dual FR3 and switching controllers at runtime. |

## crisp_controllers architecture

A single shared library exporting four `controller_interface::ControllerInterface` plugins via
`crisp_controllers.xml` (`CartesianController`, `CartesianAdmittanceController`, `StateBroadcaster`,
`TorqueFeedbackController`; `PoseBroadcaster` and `TwistBroadcaster` are backwards-compatible
aliases that map to `StateBroadcaster`). All are **torque/effort** controllers.

The recurring pattern across every controller:

- **Pinocchio** supplies the model. The URDF is taken from `robot_description`, and kinematics,
  frame Jacobians, mass matrix, Coriolis, and gravity all come from `pinocchio::Model`/`Data`. Note
  `q` (dimension `nv`) and `q_pin` (dimension `nq`) are distinct — continuous joints make these
  differ.
- **`generate_parameter_library`** generates the parameter struct and `ParamListener` from the
  `src/*.yaml` sibling of each `.cpp`. To add or change a controller parameter, edit that YAML —
  never hand-write the parameter plumbing. Each generated library is declared in `CMakeLists.txt`.
- **`realtime_tools::RealtimeBuffer`** carries every subscription payload from the ROS callback into
  `update()`. Subscriptions are created in `on_configure`/`on_activate`; `update()` only reads the
  buffer via the `parse_target_*_()` helpers.
- Every Eigen vector/matrix used in `update()` is a preallocated member, sized once during
  configuration.
- The torque output is assembled as a sum of named contributions (`tau_task`, `tau_nullspace`,
  `tau_joint_limits`, `tau_friction`, `tau_coriolis`, `tau_gravity`, `tau_wrench`) into `tau_d`.
  `CartesianController` serves impedance control, operational-space control
  (`use_operational_space: true`), gravity-compensation-only, and joint impedance
  (`nullspace.projector_type: none`) purely through parameters — the FR3 demo config instantiates
  the same plugin type four times under different controller names.

### Multi-distro support

The `crisp_controllers` submodule supports all ROS 2 distros from one branch using compile-time
macros in `include/crisp_controllers/utils/ros2_version.hpp` (`ROS2_VERSION_ABOVE_HUMBLE`,
`REALTIME_TOOLS_NEW_API`, `HAS_ROS2_CONTROL_INTROSPECTION`). Humble and newer distros differ in the
include path of generated parameter headers and in the realtime_tools API. **This workspace pins
Humble**, but changes must not break the non-Humble branches of those `#if`s.

### Controller interface (topics)

Relative to the controller's namespace. `CartesianController` subscribes `target_pose`
(`PoseStamped`), `target_joint` (`JointState`), `target_wrench` (`WrenchStamped`), and a
parameter-named variable-stiffness topic (`Float64MultiArray`); it warns and drops messages when
more than one publisher is detected on a target topic. `StateBroadcaster` publishes pose, twist, raw
wrench, external wrench, external effort, and joint state on parameter-named topics, all through
`RealtimePublisher`.

Cartesian targets are consumed as raw values — the controllers do **not** transform
`PoseStamped.header.frame_id`. In the dual-FR3 demo the reference frame is `world` (a level frame
midway between the two bases), and descriptions are published as `/left/robot_description` and
`/right/robot_description` with no combined `/robot_description`.

## Hardware vs. simulation

`config/<robot>/*.ros2_control.urdf.xacro` selects the hardware plugin: `franka_hardware/
FrankaHardwareInterface` for real hardware, `crisp_mujoco_sim/Simulator` for simulation. The MuJoCo
simulator plugin is **not** part of this workspace — it comes from the demo overlay Docker images
built by `src/crisp_controllers_demos/docker-compose.yaml` (`launch_franka`, `launch_dual_franka`,
`launch_iiwa`, `launch_kinova`, …). Launching a sim robot from this workspace's container will fail
to load that plugin unless it has been provided separately.

## README drift

`README.md`'s "Python environment setup" section and the OSC demo step reference `crisp_py`
(`/ros2_ws/.venv`, `/ros2_ws/src/crisp_py/`). Neither the virtualenv nor a `crisp_py` checkout
exists in this workspace — `crisp_py` is a separate upstream repo and is not a submodule here.
Those steps cannot be followed as written until it is cloned in.
