module color;

import nullable;

const Nullable!(const Color) ColorNone;
const ColorRed = Color(255, 0, 0, true);
const ColorBlue = Color(0, 0, 255, true);
const ColorGreen = Color(0, 255, 0, true);

struct Color {
	ubyte r, g, b;
	bool visible;
}