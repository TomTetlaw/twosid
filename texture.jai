
texture :: struct {
    Path: string;
    Width, Height: int;
    Pixels: *u8;
    PixelSize: int;
    Format: texture_format;
    GpuTexture: *SDL_GPUTexture;
}

texture_format :: enum {
    RGBA;
    RGB;
    R;
}

InitTextureSystem :: () {
    Files := file_list("textures");
    for Files {
        if contains(it, ".png") {
            Path, base_name, ext := path_decomp(it);
            LoadTexture(tprint("textures/%.%", base_name, ext));
        }
    }
    
    TotalTexturesSize := 0;
    for * Textures {
        TotalTexturesSize += it.Width * it.Height * it.PixelSize;
        
        TextureInfo: SDL_GPUTextureCreateInfo;
        TextureInfo.type = .SDL_GPU_TEXTURETYPE_2D;
        TextureInfo.format = .SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM;
        TextureInfo.width = xx it.Width;
        TextureInfo.height = xx it.Height;
        TextureInfo.layer_count_or_depth = 1;
        TextureInfo.num_levels = 11;
        TextureInfo.usage = SDL_GPU_TEXTUREUSAGE_SAMPLER | SDL_GPU_TEXTUREUSAGE_COLOR_TARGET;
        
        it.GpuTexture = SDL_CreateGPUTexture(GDevice, *TextureInfo);
        SDL_SetGPUTextureName(GDevice, it.GpuTexture, it.Path.data);
    }
    
    CreateInfo: SDL_GPUTransferBufferCreateInfo;
    CreateInfo.usage = .SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD;
    CreateInfo.size = xx TotalTexturesSize;
    TransferBuffer := SDL_CreateGPUTransferBuffer(GDevice, *CreateInfo);
    TransferMemory := cast(*u8) SDL_MapGPUTransferBuffer(GDevice, TransferBuffer, false);
    
    Cursor := 0;
    for * Textures {
        Size := it.Width * it.Height * it.PixelSize;
        memcpy(TransferMemory + Cursor, it.Pixels, Size);
        Cursor += Size;
    }
    
    SDL_UnmapGPUTransferBuffer(GDevice, TransferBuffer);
    
    CommandBuffer := SDL_AcquireGPUCommandBuffer(GDevice);
    CopyPass := SDL_BeginGPUCopyPass(CommandBuffer);
    
    Cursor = 0;
    for * Textures {
        Size := it.Width * it.Height * it.PixelSize;
        Info: SDL_GPUTextureTransferInfo;
        Info.transfer_buffer = TransferBuffer;
        Info.offset = xx Cursor;
        Info.pixels_per_row = xx it.Width;
        Info.rows_per_layer = xx it.Height;
        
        Region: SDL_GPUTextureRegion;
        Region.texture = it.GpuTexture;
        Region.w = xx it.Width;
        Region.h = xx it.Height;
        Region.d = 1;
        
        SDL_UploadToGPUTexture(CopyPass, *Info, *Region, false);
        Cursor += Size;
    }
    
    SDL_EndGPUCopyPass(CopyPass);
    
    for * Textures {
        SDL_GenerateMipmapsForGPUTexture(CommandBuffer, it.GpuTexture);
    }
    
    SDL_SubmitGPUCommandBuffer(CommandBuffer);
    SDL_ReleaseGPUTransferBuffer(GDevice, TransferBuffer);
    
    for * Textures {
        stb_image_free(it.Pixels);
        it.Pixels = null;
    }
}

LoadTexture :: (Path: string) -> *texture {
    for * Textures if equal(it.Path, Path) return it;
    
    Width, Height, Channels: s32;
    Pixels := stb_load_image(Path.data, *Width, *Height, *Channels, 4);
    if !Pixels return ArenaPushNull(texture);
    
    Texture := ArenaPush(*Textures);
    Texture.Path = Path;
    Texture.Width = xx Width;
    Texture.Height = xx Height;
    Texture.Pixels = Pixels;
    Texture.Format = .RGBA;
    Texture.PixelSize = 4;
    
    return Texture;
}

#scope_file

Textures: arena(texture);

#import "Basic";
#import "String";