// stb_image

stb_load_image :: (filename: *u8, x: *s32, y: *s32, channels_in_file: *s32, desired_channels: s32) -> *u8 
#foreign stb_image "stbi_load";

stb_image_free :: (memory: *void) 
#foreign stb_image "stbi_image_free";

// stb_truetype

/*
Stb_Buffer :: struct {
    data: *u8;
    cursor: s32;
    size: s32;
}

Stb_Aligned_Quad :: struct {
    x0: float32;
    y0: float32;
    s0: float32;
    t0: float32;
    x1: float32;
    y1: float32;
    s1: float32;
    t1: float32;
}

Stb_Packed_Char :: struct {
    x0: u16;
    y0: u16;
    x1: u16;
    y1: u16;
    xoff: float32;
    yoff: float32;
    xadvance: float32;
    xoff2: float32;
    yoff2: float32;
}

Stb_Pack_Context :: struct {
    userAllocatorContext: *void;
    packInfo: *void;
    width: s32;
    height: s32;
    strideInBytes: s32;
    padding: s32;
    skipMissing: s32;
    h_oversample: u32;
    v_oversample: u32;
    pixels: *u8;
    nodes: *void;
}

Stb_Font_Info :: struct {
    userdata : *void;
    data: *u8;
    fontstart: s32;
    numGlyphs: s32;
    loca: s32;
    head: s32;
    glyf: s32;
    hhea: s32;
    hmtx: s32;
    kern: s32;
    gpos: s32;
    svg: s32;
    indexMap: s32;
    indexToLocFormat: s32;
    cff: Stb_Buffer;
    charstrings: Stb_Buffer;
    gsubrs: Stb_Buffer;
    subrs: Stb_Buffer;
    fontdicts: Stb_Buffer;
    fdselect: Stb_Buffer;
}

stb_pack_begin :: (spc: *Stb_Pack_Context, pixels: *u8, width: s32, height: s32, strideInBytes: s32, padding: s32, allocContext: *void) -> s32 
#foreign stb_truetype "stbtt_PackBegin";

stb_pack_end :: (spc: *Stb_Pack_Context)
#foreign stb_truetype "stbtt_PackEnd";

stb_pack_font_range :: (spc: *Stb_Pack_Context, fontdata: *u8, fontIndex: s32, fontSize: float32,
                        firstUnicodeCharInRange: s32, numCharsInRange: s32, chardataForRange: *Stb_Packed_Char) -> s32 
#foreign stb_truetype "stbtt_PackFontRange";

stb_get_packed_quad :: (chardata: *Stb_Packed_Char, pw: s32, ph: s32, charIndex: s32, xpos: *float32, ypos: *float32, q: *Stb_Aligned_Quad, alignToInteger: s32) -> void 
#foreign stb_truetype "stbtt_GetPackedQuad";

stb_get_font_offset_for_index :: (data: *u8, index: s32) -> s32 
#foreign stb_truetype "stbtt_GetFontOffsetForIndex";

stb_init_font :: (info: *Stb_Font_Info, data: *u8, offset: s32) -> s32 
#foreign stb_truetype "stbtt_InitFont";

stb_scale_for_pixel_height :: (info: *Stb_Font_Info, pixels: float32) -> float32 
#foreign stb_truetype "stbtt_ScaleForPixelHeight";

stb_get_font_v_metrics :: (info: *Stb_Font_Info, ascent: *s32, descent: *s32, lineGap: *s32) -> void 
#foreign stb_truetype "stbtt_GetFontVMetrics";

stb_get_codepoint_h_metrics :: (info: *Stb_Font_Info, codepoint: s32, advanceWidth: *s32, leftSideBearing: *s32) -> void 
#foreign stb_truetype "stbtt_GetCodepointHMetrics";
*/
#scope_file

//stb_truetype :: #library "lib/stb_truetype";
stb_image :: #library "lib/stb_image";