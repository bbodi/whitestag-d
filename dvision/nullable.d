module nullable;

import std.traits, std.range;
import std.typetuple : TypeTuple, allSatisfy;

struct Nullable(T)
{
    private T _value;
    private bool _isNull = true;

	/**
	Constructor initializing $(D this) with $(D value).
	*/
    this(inout T value) inout
    {
        _value = value;
        _isNull = false;
    }

	/**
	Returns $(D true) if and only if $(D this) is in the null state.
	*/
    @property bool isNull() const pure nothrow @safe
    {
        return _isNull;
    }

	/**
	Forces $(D this) to the null state.
	*/
    void nullify()()
    {
        .destroy(_value);
        _isNull = true;
    }

	/**
	Assigns $(D value) to the internally-held state. If the assignment
	succeeds, $(D this) becomes non-null.
	*/
    void opAssign()(T value)
    {
        _value = value;
        _isNull = false;
    }



	/**
	Gets the value. $(D this) must not be in the null state.
	This function is also called for the implicit conversion to $(D T).
	*/
    @property ref inout(T) get() inout pure nothrow @safe
    {
        enum message = "Called `get' on null Nullable!" ~ T.stringof ~ ".";
        assert(!isNull, message);
        return _value;
    }
}

Nullable!(T) none()() pure {
	return Nullable!T();
}

Nullable!(T) some(T)(T value) pure {
	Nullable!(T) ret = value;
	return ret;
}

unittest
{
	import testhelper;
	test("get() must be used to extract the stored value", {
		static assert( __traits(compiles, { Nullable!int(3) == 3; }) == false);
	});

	test("Nullable!someStruct = Nullable!someStruct should work", {
		struct TestStruct {int val;}
		Nullable!TestStruct a = TestStruct();
		a.get.val = 3;
		immutable Nullable!TestStruct b = a;
		Nullable!TestStruct c;
		c = b;
		assert(b.get.val == 3);
		assert(c.get.val == 3);
	});
}

unittest
{
    import std.exception : assertThrown;

    Nullable!int a;
    assert(a.isNull);
    assertThrown!Throwable(a.get);
    a = 5;
    assert(!a.isNull);
    assert(a.get == 5);
    assert(a.get != 3);
    a.nullify();
    assert(a.isNull);
    a = 3;
    assert(a.get == 3);
    a.get *= 6;
    assert(a.get == 18);
    a = a;
    assert(a.get == 18);
    a.nullify();
    assertThrown!Throwable(a.get += 2);
}
unittest
{
    auto k = Nullable!int(74);
    assert(k.get == 74);
    k.nullify();
    assert(k.isNull);
}
unittest
{
    static int f(in Nullable!int x) {
        return x.isNull ? 42 : x.get;
    }
    Nullable!int a;
    assert(f(a) == 42);
    a = 8;
    assert(f(a) == 8);
    a.nullify();
    assert(f(a) == 42);
}
unittest
{
    import std.exception : assertThrown;

    static struct S { int x; }
    Nullable!S s;
    assert(s.isNull);
    s = S(6);
    assert(s.get == S(6));
    assert(s.get != S(0));
    s.get.x = 9190;
    assert(s.get.x == 9190);
    s.nullify();
    assertThrown!Throwable(s.get.x = 9441);
}
unittest
{
    // Ensure Nullable can be used in pure/nothrow/@safe environment.
    function() pure nothrow @safe
    {
        Nullable!int n;
        assert(n.isNull);
        n = 4;
        assert(!n.isNull);
        assert(n.get == 4);
        n.nullify();
        assert(n.isNull);
    }();
}
unittest
{
    // Ensure Nullable can be used when the value is not pure/nothrow/@safe
    static struct S
    {
        int x;
        this(this) @system {}
    }

    Nullable!S s;
    assert(s.isNull);
    s = S(5);
    assert(!s.isNull);
    assert(s.get.x == 5);
    s.nullify();
    assert(s.isNull);
}
unittest
{
    // Bugzilla 9404
    alias N = Nullable!int;

    void foo(N a)
    {
        N b;
        b = a; // `N b = a;` works fine
    }
    N n;
    foo(n);
}
unittest
{
    //Check nullable immutable is constructable
    {
        auto a1 = Nullable!(immutable int)();
        auto a2 = Nullable!(immutable int)(1);
        auto i = a2.get;
    }
    //Check immutable nullable is constructable
    {
        auto a1 = immutable (Nullable!int)();
        auto a2 = immutable (Nullable!int)(1);
        auto i = a2.get;
    }
}
unittest
{
    alias NInt   = Nullable!int;

    //Construct tests
    {
        //from other Nullable null
        NInt a1;
        NInt b1 = a1;
        assert(b1.isNull);

        //from other Nullable non-null
        NInt a2 = NInt(1);
        NInt b2 = a2;
        assert(b2.get == 1);

        //Construct from similar nullable
        auto a3 = immutable(NInt)();
        NInt b3 = a3;
        assert(b3.isNull);
    }

    //Assign tests
    {
        //from other Nullable null
        NInt a1;
        NInt b1;
        b1 = a1;
        assert(b1.isNull);

        //from other Nullable non-null
        NInt a2 = NInt(1);
        NInt b2;
        b2 = a2;
        assert(b2.get == 1);

        //Construct from similar nullable
        auto a3 = immutable(NInt)();
        NInt b3 = a3;
        b3 = a3;
        assert(b3.isNull);
    }
}
unittest
{
    //Check nullable is nicelly embedable in a struct
    static struct S1
    {
        Nullable!int ni;
    }
    static struct S2 //inspired from 9404
    {
        Nullable!int ni;
        this(S2 other)
        {
            ni = other.ni;
        }
        void opAssign(S2 other)
        {
            ni = other.ni;
        }
    }
    foreach (S; TypeTuple!(S1, S2))
    {
        S a;
        S b = a;
        S c;
        c = a;
    }
}
unittest
{
    // Bugzilla 10268
    import std.json;
    JSONValue value = null;
    auto na = Nullable!JSONValue(value);

    struct S1 { int val; }
    struct S2 { int* val; }
    struct S3 { immutable int* val; }

    {
        auto sm = S1(1);
        immutable si = immutable S1(1);
        static assert( __traits(compiles, { auto x1 =           Nullable!S1(sm); }));
        static assert( __traits(compiles, { auto x2 = immutable Nullable!S1(sm); }));
        static assert( __traits(compiles, { auto x3 =           Nullable!S1(si); }));
        static assert( __traits(compiles, { auto x4 = immutable Nullable!S1(si); }));
    }

    auto nm = 10;
    immutable ni = 10;

    {
        auto sm = S2(&nm);
        immutable si = immutable S2(&ni);
        static assert( __traits(compiles, { auto x =           Nullable!S2(sm); }));
        static assert(!__traits(compiles, { auto x = immutable Nullable!S2(sm); }));
        static assert(!__traits(compiles, { auto x =           Nullable!S2(si); }));
        static assert( __traits(compiles, { auto x = immutable Nullable!S2(si); }));
    }

    {
        auto sm = S3(&ni);
        immutable si = immutable S3(&ni);
        static assert( __traits(compiles, { auto x =           Nullable!S3(sm); }));
        static assert( __traits(compiles, { auto x = immutable Nullable!S3(sm); }));
        static assert( __traits(compiles, { auto x =           Nullable!S3(si); }));
        static assert( __traits(compiles, { auto x = immutable Nullable!S3(si); }));
    }
}
unittest
{
    // Bugzila 10357
    import std.datetime;
    Nullable!SysTime time = SysTime(0);
}