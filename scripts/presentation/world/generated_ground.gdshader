shader_type canvas_item;
render_mode unshaded;
uniform sampler2D terrain_codes : filter_linear, repeat_disable;
uniform sampler2D ground_wash : source_color, filter_linear, repeat_disable;
uniform bool has_ground = false;
uniform float chart_seed = 1.0;
uniform vec2 terrain_texel = vec2(0.0052083333,0.0092592593);
uniform bool climate_enabled = false;
float hash21(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7))+chart_seed*.013)*43758.5453); }
float noise21(vec2 p) {
    vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
    return mix(mix(hash21(i),hash21(i+vec2(1,0)),f.x),mix(hash21(i+vec2(0,1)),hash21(i+vec2(1,1)),f.x),f.y);
}
float fbm(vec2 p) { return noise21(p)*.56+noise21(p*2.03)*.28+noise21(p*4.07)*.12+noise21(p*8.11)*.04; }
void fragment() {
    vec2 texel=terrain_texel;
    vec2 uv=clamp(UV+(vec2(noise21(UV*80.0),noise21(UV*80.0+37.0))-.5)*texel*.65,vec2(0),vec2(1));
    vec3 weights=texture(terrain_codes,uv).rgb*.4;
    weights+=texture(terrain_codes,uv+texel*vec2(.6,.6)).rgb*.15;
    weights+=texture(terrain_codes,uv+texel*vec2(-.6,.6)).rgb*.15;
    weights+=texture(terrain_codes,uv+texel*vec2(.6,-.6)).rgb*.15;
    weights+=texture(terrain_codes,uv-texel*.6).rgb*.15;
    float water=smoothstep(.38,.62,weights.r);
    float broad=fbm(UV*vec2(27,16));
    float grain=noise21(UV*vec2(1100,620));
    vec3 wash=has_ground ? texture(ground_wash,UV*.78+.10).rgb : vec3(.71,.59,.34);
    vec3 land=mix(vec3(.69,.57,.33),wash,.75);
    float climate=climate_enabled ? (texture(terrain_codes,uv).a-.5)*2.0 : 0.0;
    land=mix(land,land*vec3(.84,1.02,.86),max(0.0,climate)*.7);
    land=mix(land,land*vec3(1.06,.95,.77),max(0.0,-climate)*.75);
    land=mix(land,land*vec3(.81,.91,.74),smoothstep(.10,.90,weights.g)*.68);
    land=mix(land,land*vec3(.88,.84,.77),weights.b*.38);
    land*=.94+broad*.12;
    float waves=pow(max(0.0,sin(UV.y*420.0+fbm(UV*50.0)*24.0)),18.0);
    vec3 sea=vec3(.31,.46,.44)*(.89+broad*.18);
    sea=mix(sea,vec3(.71,.73,.59),waves*.10);
    vec3 inked=mix(land,sea,water)+(grain-.5)*.035;
    float shore=smoothstep(.35,.58,weights.r)*(1.0-smoothstep(.60,.84,weights.r));
    inked=mix(inked,vec3(.70,.65,.43),shore*.5);
    float edge=min(min(UV.x,1.0-UV.x),min(UV.y,1.0-UV.y));
    float tear=noise21(UV*220.0)*.004;
    inked=mix(vec3(.19,.12,.045),inked,smoothstep(.002+tear,.016+tear,edge));
    COLOR=vec4(inked,smoothstep(tear,.003+tear,edge));
}
