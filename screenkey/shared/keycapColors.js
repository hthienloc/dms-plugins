// Keyviz's relative oklch() colors change only perceptual lightness.
// OKLab's a/b coordinates preserve the same chroma and hue without polar math.
function shiftLightness(color, amount) {
    function linear(v) { return v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); }
    function srgb(v) {
        const c = v <= 0.0031308 ? 12.92 * v : 1.055 * Math.pow(v, 1 / 2.4) - 0.055;
        return Math.max(0, Math.min(1, c));
    }
    const r = linear(color.r), g = linear(color.g), b = linear(color.b);
    const l = Math.cbrt(0.4122214708*r + 0.5363325363*g + 0.0514459929*b);
    const m = Math.cbrt(0.2119034982*r + 0.6806995451*g + 0.1073969566*b);
    const s = Math.cbrt(0.0883024619*r + 0.2817188376*g + 0.6299787005*b);
    const light = Math.max(0, Math.min(1, 0.2104542553*l + 0.793617785*m - 0.0040720468*s + amount));
    const a = 1.9779984951*l - 2.428592205*m + 0.4505937099*s;
    const bb = 0.0259040371*l + 0.7827717662*m - 0.808675766*s;
    const ll = Math.pow(light + 0.3963377774*a + 0.2158037573*bb, 3);
    const mm = Math.pow(light - 0.1055613458*a - 0.0638541728*bb, 3);
    const ss = Math.pow(light - 0.0894841775*a - 1.291485548*bb, 3);
    return Qt.rgba(srgb(4.0767416621*ll - 3.3077115913*mm + 0.2309699292*ss),
                   srgb(-1.2684380046*ll + 2.6097574011*mm - 0.3413193965*ss),
                   srgb(-0.0041960863*ll - 0.7034186147*mm + 1.707614701*ss), color.a);
}

function cssToRgba(value) {
    if (typeof value !== "string") return null;
    let hex = value.trim();
    if (/^#[0-9a-f]{4}$/i.test(hex)) hex = "#" + hex.slice(1).split("").map(c => c + c).join("");
    const rgb = /^#[0-9a-f]{6}$/i.test(hex);
    const rgba = /^#[0-9a-f]{8}$/i.test(hex);
    if (!rgb && !rgba) return null;
    return {
        r: parseInt(hex.slice(1, 3), 16) / 255,
        g: parseInt(hex.slice(3, 5), 16) / 255,
        b: parseInt(hex.slice(5, 7), 16) / 255,
        a: rgba ? parseInt(hex.slice(7, 9), 16) / 255 : 1
    };
}

function toCss(r, g, b, a) {
    const pair = v => ("0" + Math.round(Math.max(0, Math.min(1, v)) * 255).toString(16)).slice(-2);
    const rgb = "#" + pair(r) + pair(g) + pair(b);
    return (a === undefined || a === null || a >= 1) ? rgb : rgb + pair(a);
}

function cssColor(value) {
    if (typeof value !== "string") return value;
    const c = cssToRgba(value);
    return c ? Qt.rgba(c.r, c.g, c.b, c.a) : Qt.color(value);
}
