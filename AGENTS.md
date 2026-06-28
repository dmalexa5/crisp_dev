# Scope

This repo is a ROS 2 Humble workspace, and contains low-level ROS 2 / `ros2_control` functionality intended to run inside a Docker container.

Prioritize correctness, hardware safety, real-time safety, and small, reviewable changes.

## Environment

If a missing dependency is an apt/ROS system dependency, check that the environment is sourced, then update the Dockerfile or rosdep file. Do not pip-install ROS packages.

## Editing Rules

- Prefer small, focused diffs.
- Do not rewrite unrelated files.
- Follow existing design patterns unless there is a clear reason not to.
- Do not change public message, service, or action definitions unless explicitly instructed.
- Keep launch arguments explicit.
- Do not hardcode robot IPs unless the existing file already does.
- Prefer `PathJoinSubstitution` and package share lookups over absolute paths.
- Do not create, build, or run tests unless explicitly requested.

## `ros2_control` Plugin Rules

When editing or adding controllers/hardware plugins, verify:

- Plugin XML entries are correct.
- `pluginlib_export_plugin_description_file(...)` is present.
- CMake exports and dependencies are correct.
- Runtime class names match plugin XML declarations.

Controller lifecycle requirements:

- Validate parameters before activation.
- Prefer explicit, actionable error messages in `on_configure()`.
- Fail early on invalid configuration.

## Real-Time Safety

Inside `update()` or any real-time control path:

- Do not allocate memory.
- Do not call blocking ROS APIs.
- Do not log every control tick.
- Do not perform file I/O, parameter service calls, sleeps, or dynamic discovery.
- Use `realtime_tools::RealtimeBuffer` for non-RT to RT data transfer.
- Keep Eigen matrices preallocated where practical.

## Hardware Safety

Never run commands that may move the robot, activate real controllers, command effort/torque, start teleop, or connect to the real Franka FCI unless explicitly instructed.

Safe commands include:

```bash
colcon build
colcon test
ros2 launch <package> <launch_file> --show-args
ros2 pkg prefix <package>
ros2 interface show <interface>
```
