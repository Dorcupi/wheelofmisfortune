shader_type canvas_item;

uniform float mouth_height : hint_range(0.0, 50.0) = 15.0;
uniform float talk_speed : hint_range(0.0, 20.0) = 10.0;
uniform float talk_intensity : hint_range(0.0, 1.0) = 1.0;

void vertex() {
    float wave = sin(TIME * talk_speed) * mouth_height * talk_intensity;
    VERTEX.y += wave;
}