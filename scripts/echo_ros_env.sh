#!/usr/bin/env bash
source /opt/ros/humble/setup.bash
source install/setup.bash 2>/dev/null || true

echo "ROS_DISTRO=${ROS_DISTRO:-}"
echo "ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-}"
echo "RMW_IMPLEMENTATION=${RMW_IMPLEMENTATION:-}"

which ros2