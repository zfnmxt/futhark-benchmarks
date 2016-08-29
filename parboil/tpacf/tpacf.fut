-- An implementation of the tpacf benchmark from the parboil benchmark suite
--
-- ==
-- compiled input @ small/input-data
-- output @ small/output-data
-- compiled input @ medium/input-data
-- output @ medium/output-data
-- compiled input @ large/input-data
-- output @ large/output-data

--default(f32)

type vec3 = (f64, f64, f64)

fun pi(): f64 = 3.1415926535897932384626433832795029f64
fun dec2rad(dec: f64): f64 = pi()/180.0f64 * dec
fun rad2dec(rad: f64): f64 = 180.0f64/pi() * rad
fun min_arcmin(): f64 = 1.0f64
fun max_arcmin(): f64 = 10000.0f64
fun bins_per_dec(): f64 = 5.0f64
fun numBins(): i32 = 20

fun iota32(num: i32): [num]f64 =
    map f64 (iota(num))

-- Prøv streamRed i stedet
fun sumBins(bins: [numBinss][numBins]i32): *[numBins]i32 =
    map (fn (binIndex: []i32): i32  => reduce (+) 0i32 binIndex) (transpose(bins))

fun log10(num: f64): f64 = log64(num) / log64(10.0)

fun doCompute(data1: 
    [num1]vec3,
    data2: [num2]vec3,
    numBins: i32,
    numBins2: i32,
    binb: [numBBins]f64
): *[numBins2]i32 =
    let value = map (fn (xOuter: f64, yOuter: f64, zOuter: f64): *[numBins2]i32  =>
            streamMap (fn (chunk: int) (inner: []vec3): *[numBins2]i32  =>
                    loop (dBins = replicate numBins2 0i32) = for i < chunk do
                        let (xInner, yInner, zInner) = inner[i]
                        let dot = xOuter * xInner + yOuter * yInner + zOuter * zInner
                        loop ((min, max) = (0, numBins)) = while (min+1) < max do
                            let k = (min+max) / 2 in
                            unsafe if dot >= binb[k]
                            then (min, k)
                            else (k, max)
                        in
                        let index = unsafe if dot >= binb[min]
                                    then min
                                    else if dot < binb[max]
                                        then max+1
                                        else max
                        in
                        unsafe let dBins[index] = dBins[index] + 1i32 in dBins
                    in dBins
                ) data2
        ) data1
    in
    sumBins(value)

fun doComputeSelf(data: 
    [numD]vec3,
    numBins: i32,
    numBins2: i32,
    binb: [numBBins]f64
): *[numBins2]i32 =
-- loop version
    let value = map (fn (vec: vec3, index: i32): [numBins2]i32  =>
                    let (xOuter, yOuter, zOuter) = vec
                    loop (dBins = replicate numBins2 0i32) = for (index+1) <= j < numD do
                        let (xInner, yInner, zInner) = data[j]
                        let dot = xOuter * xInner + yOuter * yInner + zOuter * zInner
                        loop ((min, max) = (0, numBins)) = while (min+1) < max do
                            let k = (min+max) / 2 in
                            unsafe if dot >= binb[k]
                            then (min, k)
                            else (k, max)
                        in
                        let index = unsafe if dot >= binb[min]
                                    then min
                                    else if dot < binb[max]
                                        then max+1
                                        else max
                        in
                        unsafe let dBins[index] = dBins[index] + 1i32 in dBins
                    in dBins
                ) (zip data (iota(numD)))
    in
    sumBins(value)

fun fixPoints(ra: f64, dec: f64): vec3 =
    let rarad = dec2rad(ra)
    let decrad = dec2rad(dec)
    let cd = cos64(decrad)
    in
    (cos64(rarad)*cd, sin64(rarad)*cd, sin64(decrad))

fun main(datapointsx: 
    [numD]f64,
    datapointsy: [numD]f64,
    randompointsx: [numRs][numR]f64,
    randompointsy: [numRs][numR]f64
): *[60]i32 =
    let numBins2 = numBins() + 2
    let binb = map (fn (k: f64): f64  =>
                        cos64((10.0 ** (log10(min_arcmin()) + k*1.0/bins_per_dec())) / 60.0 * dec2rad(1.0))) (
                    iota32(numBins() + 1))
    let datapoints = map fixPoints (zip datapointsx datapointsy)
    let randompoints = map (fn (x: [numR]f64, y: [numR]f64): [numR]vec3  =>
                            map fixPoints (zip x y)) (
                           zip randompointsx randompointsy)
    let (rrs, drs) = unzip(map (fn (random: [numR]vec3): (*[]i32, *[]i32)  =>
                                (doComputeSelf(random, numBins(), numBins2, binb),
                                doCompute(datapoints, random, numBins(), numBins2, binb))) randompoints)
    loop ((res, dd, rr, dr) = (replicate (numBins()*3) 0i32,
                               doComputeSelf(datapoints, numBins(), numBins2, binb),
                               sumBins(rrs),
                               sumBins(drs))) = for i < numBins() do
        let res[i*3] = dd[i+1]
        let res[i*3+1] = dr[i+1]
        let res[i*3+2] = rr[i+1]
        in
        (res, dd, rr, dr)
    in
    res
