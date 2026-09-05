shader_type canvas_item;
render_mode unshaded;

uniform float walk_phase = 0.0;
uniform float walk_amount : hint_range(0.0, 1.0) = 0.0;

void vertex() {
	// The source figures are full-body cutouts. Move the left and right lower halves
	// in opposite directions to produce a readable alternating stride.
	float lower_body = smoothstep(0.58, 0.98, UV.y);
	float leg_side = UV.x < 0.5 ? 1.0 : -1.0;
	float stride = sin(walk_phase) * leg_side * walk_amount;
	VERTEX.x += stride * lower_body * 34.0;
	VERTEX.y -= abs(cos(walk_phase)) * lower_body * walk_amount * 5.0;
}
