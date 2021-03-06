local module = {}

local permutation = {
    160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,
    37,240,21,10,23,190,6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,
    32,57,177,33,88,237,149,56,87,174,20,125,136,171,168,68,175,74,165,71,134,139,
    48,27,166,77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,
    40,244,102,143,54,65,25,63,161,1,216,80,73,209,76,132,187,208,89,18,169,200,
    196,135,130,116,188,159,86,164,100,109,198,173,186,3,64,52,217,226,250,124,123,
    5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
    223,183,170,213,119,248,152,2,44,154,163,70,221,153,101,155,167,43,172,9,
    129,22,39,253,19,98,108,110,79,113,224,232,178,185,112,104,218,246,97,228,
    251,34,242,193,238,210,144,12,191,179,162,241,81,51,145,235,249,14,239,107,
    49,192,214,31,181,199,106,157,184,84,204,176,115,121,50,45,127,4,150,254,
    138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180
}

permutation[0] = 151
for i = 0,255 do
    permutation[i+256] = permutation[i]
end

local mag_distr_t = {}
do
    local s = 1
    for i=0,255 do
        mag_distr_t[i] = s
        s = s / 1.02
    end
end

local function fade(t)
	return 6 * t^5 - 15 * t^4 + 10 * t^3
end

local function lerp(t, a, b)
    return a + t * (b - a)
end

local dot_product = {
    [0x0]=function(x,y,z) return  x + y end,
    [0x1]=function(x,y,z) return -x + y end,
    [0x2]=function(x,y,z) return  x - y end,
    [0x3]=function(x,y,z) return -x - y end
}

local function grad(hash,x,y)
	return dot_product[hash % 4](x,y)
end

function module.Noise2D(x, y)
    local xi = math.floor(x) % 256
    local yi = math.floor(y) % 256

    local x_offset = x - math.floor(x)
    local y_offset = y - math.floor(y)

    local A,B,AA,AB,BA,BB

    A = permutation[xi]
    B = permutation[xi + 1]

    AA = permutation[A + yi]
	AB = permutation[B + yi]
	BA = permutation[A + yi + 1]
	BB = permutation[B + yi + 1]

    local fade_x = fade(x_offset)

	return lerp(
		 fade(y_offset)
		,lerp(
             fade_x
			,grad(AA, x_offset, y_offset)
			,grad(AB, x_offset - 1, y_offset)
		)
		,lerp(
			 fade_x
			,grad(BA, x_offset, y_offset - 1)
			,grad(BB, x_offset - 1, y_offset - 1)
		)
	)
end

function module.Noise2DExpDistr(x, y)
    local xi = math.floor(x) % 256
    local yi = math.floor(y) % 256

    local x_offset = x - math.floor(x)
    local y_offset = y - math.floor(y)

    local A,B,AA,AB,BA,BB

    A = permutation[xi]
    B = permutation[xi + 1]

    AA = permutation[A + yi]
	AB = permutation[B + yi]
	BA = permutation[A + yi + 1]
	BB = permutation[B + yi + 1]

    local fade_x = fade(x_offset)

	return lerp(
		 fade(y_offset)
		,lerp(
             fade_x
			,grad(AA, x_offset, y_offset) * mag_distr_t[AA % 256]
			,grad(AB, x_offset - 1, y_offset) * mag_distr_t[AB % 256]
		)
		,lerp(
			 fade_x
			,grad(BA, x_offset, y_offset - 1) * mag_distr_t[BA % 256]
			,grad(BB, x_offset - 1, y_offset - 1) * mag_distr_t[BB % 256]
		)
	)
end

return module