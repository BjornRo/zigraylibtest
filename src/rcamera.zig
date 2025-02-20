//    rcamera - Basic camera system with support for multiple camera modes
//
//    Ported from raylib.rcamera.h, without standalone features
//
//    CONTRIBUTORS:
//        Ramon Santamaria:   Supervision, review, update and maintenance
//        Christoph Wagner:   Complete redesign, using raymath (2022)
//        Marc Palau:         Initial implementation (2014)
//
//    LICENSE: zlib/libpng
//
//    Copyright (c) 2022-2025 Christoph Wagner (@Crydsch) & Ramon Santamaria (@raysan5)
//
//    This software is provided "as-is", without any express or implied warranty. In no event
//    will the authors be held liable for any damages arising from the use of this software.
//
//    Permission is granted to anyone to use this software for any purpose, including commercial
//    applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//      1. The origin of this software must not be misrepresented; you must not claim that you
//      wrote the original software. If you use this software in a product, an acknowledgment
//      in the product documentation would be appreciated but is not required.
//
//      2. Altered source versions must be plainly marked as such, and must not be misrepresented
//      as being the original software.
//
//      3. This notice may not be removed or altered from any source distribution.

const std = @import("std");
const rl = @import("raylib");
const math = std.math;
const rlm = rl.math;
const Camera = rl.Camera;
const Matrix = rl.Matrix;
const Vec2 = rl.Vector2;
const Vec3 = rl.Vector3;

//----------------------------------------------------------------------------------
// Defines
//----------------------------------------------------------------------------------
const CAMERA_MOVE_SPEED: f32 = 5.4; // Units per second
const CAMERA_ROTATION_SPEED: f32 = 0.03;
const CAMERA_PAN_SPEED: f32 = 0.2;

// Camera mouse movement sensitivity
const CAMERA_MOUSE_MOVE_SENSITIVITY: f32 = 0.003;

// Camera orbital speed in CAMERA_ORBITAL mode
const CAMERA_ORBITAL_SPEED: f32 = 0.5; // Radians per second

// Camera culling distances
const CAMERA_CULL_DISTANCE_NEAR: f64 = 0.01;
const CAMERA_CULL_DISTANCE_FAR: f64 = 1000.0;

//----------------------------------------------------------------------------------
// Module Functions Definition
//----------------------------------------------------------------------------------

/// Returns the cameras forward vector (normalized)
pub fn getCameraForward(camera: *Camera) Vec3 {
    return rlm.vector3Normalize(rlm.vector3Subtract(camera.target, camera.position));
}

/// Returns the cameras up vector (normalized)
///
/// NOTE: The up vector might not be perpendicular to the forward vector
pub fn getCameraUp(camera: *Camera) Vec3 {
    return rlm.vector3Normalize(camera.up);
}

/// Returns the cameras right vector (normalized)
pub fn getCameraRight(camera: *Camera) Vec3 {
    const forward: Vec3 = getCameraForward(camera);
    const up: Vec3 = getCameraUp(camera);

    return rlm.vector3Normalize(rlm.vector3CrossProduct(forward, up));
}

/// Helper function to translate the camera movement.
fn cameraMovement(camera: *Camera, position: Vec3, distance: f32) void {
    // Scale by distance
    const movement = rlm.vector3Scale(position, distance);

    // Move position and target
    camera.position = rlm.vector3Add(camera.position, movement);
    camera.target = rlm.vector3Add(camera.target, movement);
}

/// Moves the camera in its forward direction
pub fn cameraMoveForward(camera: *Camera, distance: f32, move_in_world_plane: bool) void {
    var forward: Vec3 = getCameraForward(camera);

    if (move_in_world_plane) {
        // Project vector onto world plane
        forward.y = 0;
        forward = rlm.vector3Normalize(forward);
    }

    cameraMovement(camera, forward, distance);
}

/// Moves the camera in its forward direction
pub fn cameraMoveUp(camera: *Camera, distance: f32) void {
    const up: Vec3 = getCameraUp(camera);

    cameraMovement(camera, up, distance);
}

/// Moves the camera target in its current right direction
pub fn cameraMoveRight(camera: *Camera, distance: f32, move_in_world_plane: bool) void {
    var right: Vec3 = getCameraRight(camera);

    if (move_in_world_plane) {
        // Project vector onto world plane
        right.y = 0;
        right = rlm.vector3Normalize(right);
    }

    cameraMovement(camera, right, distance);
}

/// Moves the camera position closer/farther to/from the camera target
pub fn cameraMoveToTarget(camera: *Camera, delta: f32) void {
    var distance = rlm.vector3Distance(camera.position, camera.target);

    // Apply delta
    distance += delta;

    // Distance must be greater than 0
    if (distance <= 0) distance = 0.001;

    const forward: Vec3 = getCameraForward(camera);
    camera.position = rlm.vector3Add(camera.target, rlm.vector3Scale(forward, -distance));
}

/// Rotates the camera around its up vector
///
/// NOTE: angle must be provided in radians
/// Yaw is "looking left and right"
/// If rotateAroundTarget is false, the camera rotates around its position
pub fn cameraYaw(camera: *Camera, angle: f32, rotate_around_target: bool) void {
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
///
/// NOTE: angle must be provided in radians
///  - lockView prevents camera overrotation (aka "somersaults")
///  - rotateAroundTarget defines if rotation is around target or around its position
///  - rotateUp rotates the up direction as well (typically only usefull in CAMERA_FREE)
pub fn cameraPitch(camera: *Camera, angle: f32, lock_view: bool, rotate_around_target: bool, rotate_up: bool) void {
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

/// Rotates the camera around its forward vector
///
/// NOTE: angle must be provided in radians
/// Roll is "turning your head sideways to the left or right"
pub fn cameraRoll(camera: *Camera, angle: f32) void {
    // Rotation axis
    const forward: Vec3 = getCameraForward(camera);

    // Rotate up direction around forward axis
    camera.up = rlm.vector3RotateByAxisAngle(camera.up, forward, angle);
}

/// Returns the camera view matrix
pub fn getCameraViewMatrix(camera: *Camera) Matrix {
    return Matrix.lookAt(camera.position, camera.target, camera.up);
}

/// Returns the camera projection matrix
pub fn getCameraProjectionMatrix(camera: *Camera, aspect: f64) Matrix {
    return switch (camera.projection) {
        .perspective => return Matrix.perspective(
            math.degreesToRadians(camera.fovy),
            aspect,
            CAMERA_CULL_DISTANCE_NEAR,
            CAMERA_CULL_DISTANCE_FAR,
        ),
        .orthographic => {
            const top: f64 = camera.fovy / 2;
            const right = top * aspect;

            return Matrix.ortho(-right, right, -top, top, CAMERA_CULL_DISTANCE_NEAR, CAMERA_CULL_DISTANCE_FAR);
        },
    };
}
