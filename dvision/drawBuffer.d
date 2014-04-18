module DrawBuffer;

import std.exception : enforce;
import std.conv : to;

import nullable;
import rect;
import color;
import testhelper;

enum TextStyle {
	Normal, Bold, Italic
}

struct Cell {
	Nullable!Color fg, bg;
	wchar ch;
	TextStyle[] styles;
}

struct DrawBuffer {
	int w, h;
	private Nullable!Cell[] cells;


	void setCellFg(int x, int y, in ref Color fg) {
		setCell(x, y, some(fg));
	}

	void setCellBg(int x, int y, in ref Color bg) {
		setCell(x, y, ColorNone, some(bg));
	}

	void setCellChar(int x, int y, in wchar ch) {
		setCell(x, y, ColorNone, ColorNone, ch);
	}

	void setCellStyles(int x, int y, in TextStyle[] styles) {
	}


	void setCell(int x, int y, in Nullable!(const Color) fg = ColorNone, 
				 Nullable!(const Color) bg = ColorNone, wchar ch = wchar.init, in TextStyle[] styles = null) pure {
		if (outOfRange(x, y)) {
			return;
		}
		const i = y * w + x;
		if (cells[i].isNull) {
			cells[i] = Cell();
		}
		modifyCell(cells[i].get, fg, bg, ch, styles);
	}

	unittest 
	{
		test("setCell Fg", {
			auto buff = createDrawBuffer(10, 10);
			buff.setCell(5, 5, some(ColorRed));
			auto cell = buff.cells[5*10+5];
			assert(cell.get.fg.get == ColorRed);
			assert(cell.get.bg.isNull);
			assert(cell.get.styles.length == 0);
			assert(cell.get.ch == wchar.init);
		});

		test("setCell Bg", {
			auto buff = createDrawBuffer(10, 10);
			buff.setCellBg(5, 5, ColorRed);
			auto cell = buff.cells[5*10+5];
			assert(cell.get.fg.isNull);
			assert(cell.get.bg.get == ColorRed);
			assert(cell.get.styles.length == 0);
			assert(cell.get.ch == wchar.init);
		});

		test("setCellChar", {
			auto buff = createDrawBuffer(10, 10);
			buff.setCellChar(5, 5, 'á');
			auto cell = buff.cells[5*10+5];
			assert(cell.get.fg.isNull);
			assert(cell.get.bg.isNull);
			assert(cell.get.styles.length == 0);
			assert(cell.get.ch == 'á');
		});
	}

	private static void modifyCell(ref Cell cell, in ref Nullable!(const Color) fg = ColorNone, in ref Nullable!(const Color) bg = ColorNone, wchar ch = wchar.init, in TextStyle[] styles = null) pure {
		if (fg.isNull == false) {
			cell.fg = fg.get;
		}
		if (bg.isNull == false) {
			cell.bg = bg.get;
		}
		if (ch != 0) {
			cell.ch = ch;
		}
		if (styles != null) {
			cell.styles = styles.dup;
		}
	}

	bool outOfRange(int x, int y) pure {
		return x >= this.w || y >= this.h || y < 0 || x < 0;
	}
}

DrawBuffer createDrawBuffer(int w, int h) {
	enforce(w >= 0 && h >= 0, to!string(w) ~ ", " ~ to!string(h));
	return DrawBuffer(w, h, new Nullable!Cell[w*h]);
}

DrawBuffer createDrawBuffer(Rect rect) {
	return createDrawBuffer(rect.w, rect.h);
}

unittest 
{
	import std.exception : assertThrown;
	test("createDrawBuffer with negative sizes throw exception!", {
		assertThrown!Throwable(createDrawBuffer(-1, 10));
		assertThrown!Throwable(createDrawBuffer(1, -10));
	});
}
