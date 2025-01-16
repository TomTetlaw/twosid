
font :: struct {
    Path: string;
    Texture: *texture;
    
    LineSkip: float;
    Scale: float;
    Size: float;
    CharWidth: float;
    
    Info: stbtt_fontinfo;
    Chars: [] stbtt_packedchar;
    
    IsDistanceFont: bool;
    DistanceTexture: *texture;
}

LoadFont :: (Path: string, Size: float) -> *font {
    for * ArenaToView(*Fonts, font) {
        if equal(Path, it.Path) && it.Size == Size return it;
    }
    
    File, Success := read_entire_file(Path);
    if !Success return ArenaAlloc(*Fonts, font);
    
    FontInfo: stbtt_fontinfo;
    stbtt_InitFont(*FontInfo, File.data, stbtt_GetFontOffsetForIndex(File.data, 0));
    Scale := stbtt_ScaleForPixelHeight(*FontInfo, Size);
    
    Width, Height: s32 = 512;
    
    Pixels := ArenaAlloc(*FontArena, xx (Width * Height));
    CharData := ArenaAlloc(*FontArena, stbtt_packedchar, 96);
    
    PackContext: stbtt_pack_context;
    stbtt_PackBegin(*PackContext, Pixels, Width, Height, Width, 1, null);
    stbtt_PackFontRange(*PackContext, File.data, 0, Size, 32, 96, CharData.data);
    stbtt_PackEnd(*PackContext);
    
    Texture := CreateFontTexture(Format("%_texture", Path), Pixels, Width, Height);
    
    Ascent, Descent, LineGap: s32;
    stbtt_GetFontVMetrics(*FontInfo, *Ascent, *Descent, *LineGap);
    LineSkip := (Ascent - Descent + LineGap) * Scale;
    
    Advance: s32;
    stbtt_GetCodepointHMetrics(*FontInfo, #char "A", *Advance, null);
    
    Font := ArenaAlloc(*Fonts, font);
    Font.Path = Path;
    Font.Texture = Texture;
    Font.LineSkip = LineSkip;
    Font.Scale = Scale;
    Font.Size = Size;
    Font.Info = FontInfo;
    Font.Chars = CharData;
    Font.CharWidth = Advance * Scale;
    Font.IsDistanceFont = false;
    
    return Font;
}

sdf_char :: struct {
    Ascii: int;
    Advance: float;
    U0, U1, V0, V1: float; // texture coords
    Left, Bottom, Right, Top: float; // layout
}

sdf_font :: struct {
    Path: string;
    Texture: *texture;
    Chars: [] sdf_char;
}

LoadDistanceFont :: (TexturePath: string) -> *sdf_font {
    for * ArenaToView(*DistanceFonts, sdf_font) {
        if equal(TexturePath, it.Path) return it;
    }
    
    DistanceTexture := LoadTexture(TexturePath);
    
    Success, Lines := file_to_array(TFormat("%", replace(TexturePath, ".png", ".csv")));
    
    Mark := GetArenaMark(*FontArena);
    for Lines {
        Values := split(it, ",");
        Char := ArenaAlloc(*FontArena, sdf_char);
        
        Char.Ascii = string_to_int(Values[0]);
        
        Char.Advance = string_to_float(Values[1]);
        
        Char.Left = string_to_float(Values[2]);
        Char.Bottom = string_to_float(Values[3]);
        Char.Right = string_to_float(Values[4]);
        Char.Top = string_to_float(Values[5]);
        
        Char.U0 = string_to_float(Values[6]) / DistanceTexture.Width;
        Char.V0 = string_to_float(Values[7]) / DistanceTexture.Height;
        Char.U1 = string_to_float(Values[8]) / DistanceTexture.Width;
        Char.V1 = string_to_float(Values[9]) / DistanceTexture.Height;
    }
    Chars := ArenaToView(*FontArena, sdf_char, Mark);
    
    Font := ArenaAlloc(*DistanceFonts, sdf_font);
    Font.Path = TexturePath;
    Font.Texture = DistanceTexture;
    Font.Chars = Chars;
    
    return Font;
}

GetCharFromDistanceFont :: (Font: *sdf_font, C: u8) -> *sdf_char {
    for Font.Chars {
        if it.Ascii == C return *it;
    }
    
    return null;
}

GetStringSize :: (Font: *font, S: string) -> float2 {
    Width := 0;
    for S {
        Advance: s32;
        stbtt_GetCodepointHMetrics(*Font.Info, it, *Advance, null);
        Width += Advance;
    }
    
    return .{Width * Font.Scale, Font.LineSkip};
}

GetStringSize :: (Font: *sdf_font, Size: float, S: string) -> float2 {
    if S.count == 0 return .{};
    
    Bottom := FLOAT32_MAX;
    Top := -FLOAT32_MAX;
    
    Advance := 0.0;
    FirstChar := GetCharFromDistanceFont(Font, S[0]);
    LastChar := GetCharFromDistanceFont(Font, S[S.count - 1]);
    
    for S {
        Char := GetCharFromDistanceFont(Font, it);
        
        Bottom = Min(Bottom, Char.Bottom);
        Top = Max(Top, Char.Top);
        
        Advance += Char.Advance;
    }
    
    TotalHeight := Top - Bottom;
    TotalWidth := Advance + (LastChar.Right - LastChar.Left);
    
    return .{TotalWidth, TotalHeight} * xy(Size);
}

#scope_file

FontArena: arena;
Fonts: arena;
DistanceFonts: arena;

#import "Text_File_Handler";
#import "stb_truetype";
