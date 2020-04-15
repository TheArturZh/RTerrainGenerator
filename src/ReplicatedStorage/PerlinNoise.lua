local perlin = {}
local p = {}

-- Hash lookup table
local permutation = {151,160,137,91,90,15,
  131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
  190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
  88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
  77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
  102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
  135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
  5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
  223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
  129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
  251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
  49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
  138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180
}

for i=0,255 do
    -- Convert to 0 based index table
    p[i] = permutation[i+1]
    -- Repeat the array to avoid buffer overflow in hash function
    p[i+256] = permutation[i+1]
end

-- Gradient magnitude table
local m = {}
local s = 1
for i=0,255 do
	m[i] = s
	s = s / 1.02
end

-- Fade function is used to smooth final output
local function fade(t)
	--return t * t * t * (t * (t * 6 - 15) + 10)
	return 6 * t^5 - 15 * t^4 + 10 * t^3
	--return -20 * t^7 + 70 * t^6 - 84 * t^5 + 35 * t^4
end

local function lerp(t, a, b)
    return a + t * (b - a)
end

local dot_product = {
    [0x0]=function(x,y,z) return  x + y end,
    [0x1]=function(x,y,z) return -x + y end,
    [0x2]=function(x,y,z) return  x - y end,
    [0x3]=function(x,y,z) return -x - y end,
    [0x4]=function(x,y,z) return  x + z end,
    [0x5]=function(x,y,z) return -x + z end,
    [0x6]=function(x,y,z) return  x - z end,
    [0x7]=function(x,y,z) return -x - z end,
    [0x8]=function(x,y,z) return  y + z end,
    [0x9]=function(x,y,z) return -y + z end,
    [0xA]=function(x,y,z) return  y - z end,
    [0xB]=function(x,y,z) return -y - z end,
    [0xC]=function(x,y,z) return  y + x end,
    [0xD]=function(x,y,z) return -y + z end,
    [0xE]=function(x,y,z) return  y - x end,
    [0xF]=function(x,y,z) return -y - z end
}

local function grad(hash, x, y, z)
    return dot_product[hash % 0x10](x,y,z)
end

local function grad2(hash,x,y)
	return dot_product[hash % 4](x,y)
end

-- Return range: [-1, 1]
function perlin.Noise3D(x, y, z)
    -- Calculate the "unit cube" that the point asked will be located in
    local xi = math.floor(x) % 256
    local yi = math.floor(y) % 256
    local zi = math.floor(z) % 256

    -- Next we calculate the location (from 0 to 1) in that cube
    x = x - math.floor(x)
    y = y - math.floor(y)
    z = z - math.floor(z)

    -- We also fade the location to smooth the result
    local u = fade(x)
    local v = fade(y)
    local w = fade(z)

    -- Hash all 8 unit cube coordinates surrounding input coordinate
    local A, AA, AB, AAA, ABA, AAB, ABB, B, BA, BB, BAA, BBA, BAB, BBB
    A   = p[xi  ] + yi
    AA  = p[A   ] + zi
    AB  = p[A+1 ] + zi
    AAA = p[ AA ]
    ABA = p[ AB ]
    AAB = p[ AA+1 ]
    ABB = p[ AB+1 ]

    B   = p[xi+1] + yi
    BA  = p[B   ] + zi
    BB  = p[B+1 ] + zi
    BAA = p[ BA ]
    BBA = p[ BB ]
    BAB = p[ BA+1 ]
    BBB = p[ BB+1 ]

    -- Take the weighted average between all 8 unit cube coordinates
    return lerp(w,
        lerp(v,
            lerp(u,
                grad(AAA,x,y,z),
                grad(BAA,x-1,y,z)
            ),
            lerp(u,
                grad(ABA,x,y-1,z),
                grad(BBA,x-1,y-1,z)
            )
        ),
        lerp(v,
            lerp(u,
                grad(AAB,x,y,z-1), grad(BAB,x-1,y,z-1)
            ),
            lerp(u,
                grad(ABB,x,y-1,z-1), grad(BBB,x-1,y-1,z-1)
            )
        )
    )
end

-- Return range: [-1, 1]
function perlin.Noise2D(x, y)
	-- Calculate the "unit square" that the point asked will be located in
    local xi = math.floor(x) % 256
    local yi = math.floor(y) % 256

	-- Next we calculate the location (from 0 to 1) in that square
    x = x - math.floor(x)
    y = y - math.floor(y)

	-- We also fade the location to smooth the result
    local u = fade(x)

    local AA,AB,BA,BB

	AA = p[p[xi]   + yi]
	AB = p[p[xi+1] + yi]
	BA = p[p[xi]   + yi + 1]
	BB = p[p[xi+1] + yi + 1]

	-- Take the weighted average between all 4 unit square coordinates
	return lerp(
		fade(y)
		,lerp(
			u
			,grad2(AA,x,y)
			,grad2(AB,x - 1,y)
		)
		,lerp(
			u
			,grad2(BA,x,y - 1)
			,grad2(BB,x - 1,y - 1)
		)
	)
end

-- Return range: [-1, 1]
function perlin.Noise2DExpDistr(x, y)
	-- Calculate the "unit square" that the point asked will be located in
    local xi = math.floor(x) % 256
    local yi = math.floor(y) % 256

	-- Next we calculate the location (from 0 to 1) in that square
    x = x - math.floor(x)
    y = y - math.floor(y)

	-- We also fade the location to smooth the result
    local u = fade(x)

    local AA,AB,BA,BB

	AA = p[p[xi]   + yi]
	AB = p[p[xi+1] + yi]
	BA = p[p[xi]   + yi + 1]
	BB = p[p[xi+1] + yi + 1]

	-- Take the weighted average between all 4 unit square coordinates
	return lerp(
		fade(y)
		,lerp(
			u
			,grad2(AA,x,y) * m[AA % 256]
			,grad2(AB,x - 1,y) * m[AB % 256]
		)
		,lerp(
			u
			,grad2(BA,x,y - 1) * m[BA % 256]
			,grad2(BB,x - 1,y - 1) * m[BB % 256]
		)
	)
end

return perlin