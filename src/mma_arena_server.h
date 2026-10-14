#ifndef MMA_ARENA_SERVER_H
#define MMA_ARENA_SERVER_H

#include <godot_cpp/classes/node3d.hpp>
#include <godot_cpp/core/class_db.hpp>

namespace godot {

class MMAArenaServer : public Node3D {
    GDCLASS(MMAArenaServer, Node3D)

private:
    double time_accumulator;
    const double FIXED_TIMESTEP = 1.0 / 60.0; // 60Hz fixed timestep (16.667ms)

protected:
    static void _bind_methods();

public:
    MMAArenaServer();
    ~MMAArenaServer();

    void _physics_process(double delta) override;

    // The 9-Stage Pipeline
    void stage1_ai_perception_and_polling();
    void stage2_stamina_and_trauma();
    void stage3_crisis_and_stoppage();
    void stage4_feint_and_cancel_router();
    void stage5_ground_grapple_denials();
    void stage6_boundary_solver();
    void stage7_skeletal_keyframes_and_ik();
    void stage8_hitbox_resolution_and_checks();
    void stage9_telemetry_and_scorecard();
};

} // namespace godot

#endif // MMA_ARENA_SERVER_H
