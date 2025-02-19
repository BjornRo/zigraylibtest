const std = @import("std");
const rl = @import("raylib");
const math = std.math;
const rlm = rl.math;
const Color = rl.Color;
const Vec2 = rl.Vector2;
const Vec3 = rl.Vector3;

fn getCameraUp(camera: *rl.Camera) Vec3 {
    return rlm.vector3Normalize(camera.up);
}

fn getCameraForward(camera: *rl.Camera) Vec3 {
    return rlm.vector3Normalize(rlm.vector3Subtract(camera.target, camera.position));
}

fn getCameraRight(camera: *rl.Camera) Vec3 {
    const forward: Vec3 = getCameraForward(camera);
    const up: Vec3 = getCameraUp(camera);

    return rlm.vector3Normalize(rlm.vector3CrossProduct(forward, up));
}

/// Rotates the camera around its up vector
/// Yaw is "looking left and right"
/// If rotateAroundTarget is false, the camera rotates around its position
/// Note: angle must be provided in radians
pub fn cameraYaw(camera: *rl.Camera, angle: f32, rotate_around_target: bool) void {
    // Rotation axis
    const up: Vec3 = getCameraUp(camera);

    // View vector
    var target_position: Vec3 = rlm.vector3Subtract(camera.target, camera.position);

    // Rotate view vector around up axis
    target_position = rlm.vector3RotateByAxisAngle(target_position, up, angle);

    if (rotate_around_target) {
        // Move position relative to target
        camera.position = rlm.vector3Subtract(camera.target, target_position);
    } else { // rotate around camera.position
        // Move target relative to position
        camera.target = rlm.vector3Add(camera.position, target_position);
    }
}

/// Rotates the camera around its right vector, pitch is "looking up and down"
///  - lockView prevents camera overrotation (aka "somersaults")
///  - rotateAroundTarget defines if rotation is around target or around its position
///  - rotateUp rotates the up direction as well (typically only usefull in CAMERA_FREE)
/// NOTE: angle must be provided in radians
pub fn cameraPitch(camera: *rl.Camera, angle: f32, lock_view: bool, rotate_around_target: bool, rotate_up: bool) void {
    var angle_ = angle;
    // Up direction
    const up: Vec3 = getCameraUp(camera);

    // View vector
    var target_position: Vec3 = rlm.vector3Subtract(camera.target, camera.position);

    if (lock_view) {
        // In these camera modes we clamp the Pitch angle
        // to allow only viewing straight up or down.

        // Clamp view up
        var max_angle_up = rlm.vector3Angle(up, target_position);
        max_angle_up -= 0.001; // avoid numerical errors
        if (angle > max_angle_up) angle_ = max_angle_up;

        // Clamp view down
        var max_angle_down = rlm.vector3Angle(rlm.vector3Negate(up), target_position);
        max_angle_down *= -1; // downwards angle is negative
        max_angle_down += 0.001; // avoid numerical errors
        if (angle < max_angle_down) angle_ = max_angle_down;
    }

    // Rotation axis
    const right: Vec3 = getCameraRight(camera);

    // Rotate view vector around right axis
    target_position = rlm.vector3RotateByAxisAngle(target_position, right, angle_);

    if (rotate_around_target) {
        // Move position relative to target
        camera.position = rlm.vector3Subtract(camera.target, target_position);
    } else { // rotate around camera.position
        // Move target relative to position
        camera.target = rlm.vector3Add(camera.position, target_position);
    }

    if (rotate_up) {
        // Rotate up direction around right axis
        camera.up = rlm.vector3RotateByAxisAngle(camera.up, right, angle_);
    }
}
