module rect;

import std.typecons;

alias Pixel = Typedef!(int, 0, "pixel");

struct Point {
	int x, y;

	bool opBinary(string op)(in ref Rect rect) if (op == "in"){
		const containsX = this.x >= rect.pX && this.x < rect.pX2;
		const containsY = this.y >= rect.pY && this.y < rect.pY2;
		return containsX && containsY;
	}
}

struct PixelRect {
	Pixel x, y, w, h;
}

Rect rectXYWH(int x, int y, int w, int h) {
	return Rect(x, y, x+w, y+h);
}

struct Rect {
	private int pX, pY, pX2, pY2;


	Rect grow(int x, int y) const {
		return Rect(pX, pY, pX2+x, pY2+y);
	}

	Rect move(int x, int y) const {
		return Rect(pX+x, pY+y, pX2+x, pY2+y);
	}

	int x() const @property { return pX; }
	int y() const @property { return pY; }
	int x2() const @property { return pX2; }
	int y2() const @property { return pY2; }
	int w() const @property { return pX2 - pX; }
	int h() const @property { return pY2 - pY; }

	void x(int newX) @property { 
		pX = newX;
	}

	void y(int newY) @property { 
		pY = newY;
	}

	void x2(int newX2) @property { 
		pX2 = newX2;
	}

	void y2(int newY2) @property { 
		pY2 = newY2;
	}

	void w(int newW) @property { 
		pX2 = pX+newW;
	}

	void h(int newH) @property { 
		pY2 = pY+newH;
	}

	Rect moveTo(int x, int y) const {
		const w = this.w;
		const h = this.h;
		return Rect(x, y, x+w, y+h);
	}
}

unittest {
	import testhelper;
	test("grow", {
		assert(rectXYWH(1, 2, 3, 4).grow(5, 6) == rectXYWH(1, 2, 8, 10));
		assert(rectXYWH(1, 2, 3, 4).move(5, 6) == rectXYWH(6, 8, 3, 4));
	});
	
	test("moveTo", {
		assert(rectXYWH(1, 2, 3, 4).moveTo(5, 6) == Rect(5, 6, 8, 10));
		assert(rectXYWH(1, 2, 3, 4).moveTo(0, 0) == Rect(0, 0, 3, 4));
		assert(rectXYWH(1, 2, 3, 4).moveTo(5, 6) == rectXYWH(5, 6, 3, 4));
		assert(rectXYWH(1, 2, 3, 4).moveTo(0, 0) == rectXYWH(0, 0, 3, 4));
	});
	
	test("contains", {
		const r = rectXYWH(1, 2, 5, 6);
		assert (Point(1, 2) in r);
		assert (Point(3, 3) in r);
		assert (Point(5, 3) in r);
		assert (Point(3, 7) in r);
		assert (Point(5, 7) in r);
		assert (Point(1, 1) !in r);
		assert (Point(7, 7) !in r);
		assert (Point(6, 8) !in r);
		const r2 = rectXYWH(0, 0, 10, 1);
		assert (Point(1, 1) !in r2);
		assert (Point(1, 0) in r2);
		assert (Point(1, 2) !in r2);
	});
}