
Texture :: struct {
    path: string;
    width, height: int;
    pixels: *u8;
    pixel_size: int;
    format: Texture_Format;
    gpu_texture: *SDL_GPUTexture;
}

Texture_Format :: enum {
    RGBA;
    RGB;
    R;
}

init_texture_system :: (gpu_device: *SDL_GPUDevice) {
    textures = create_typed_arena(Texture);
    
    files := file_list("./textures");
    for files {
        if contains(it, ".png") {
            path, base_name, ext := path_decomp(it);
            load_texture(tprint("textures/%.%", base_name, ext));
        }
    }
    
    total_textures_size := 0;
    for textures {
        total_textures_size += it.width * it.height * it.pixel_size;
        
        texture_info: SDL_GPUTextureCreateInfo;
        texture_info.type = .SDL_GPU_TEXTURETYPE_2D;
        texture_info.format = .SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM;
        texture_info.width = xx it.width;
        texture_info.height = xx it.height;
        texture_info.layer_count_or_depth = 1;
        texture_info.num_levels = 9;
        texture_info.usage = SDL_GPU_TEXTUREUSAGE_SAMPLER | SDL_GPU_TEXTUREUSAGE_COLOR_TARGET;
        
        it.gpu_texture = SDL_CreateGPUTexture(gpu_device, *texture_info);
        SDL_SetGPUTextureName(gpu_device, it.gpu_texture, it.path.data);
    }
    
    create_info: SDL_GPUTransferBufferCreateInfo;
    create_info.usage = .SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD;
    create_info.size = xx total_textures_size;
    transfer_buffer := SDL_CreateGPUTransferBuffer(gpu_device, *create_info);
    transfer_memory := cast(*u8) SDL_MapGPUTransferBuffer(gpu_device, transfer_buffer, false);
    
    cursor := 0;
    for textures {
        size := it.width * it.height * it.pixel_size;
        memcpy(transfer_memory + cursor, it.pixels, size);
        cursor += size;
    }
    
    SDL_UnmapGPUTransferBuffer(gpu_device, transfer_buffer);
    
    command_buffer := SDL_AcquireGPUCommandBuffer(gpu_device);
    copy_pass := SDL_BeginGPUCopyPass(command_buffer);
    
    cursor = 0;
    for textures {
        size := it.width * it.height * it.pixel_size;
        info: SDL_GPUTextureTransferInfo;
        info.transfer_buffer = transfer_buffer;
        info.offset = xx cursor;
        info.pixels_per_row = xx it.width;
        info.rows_per_layer = xx it.height;
        
        region: SDL_GPUTextureRegion;
        region.texture = it.gpu_texture;
        region.w = xx it.width;
        region.h = xx it.height;
        region.d = 1;
        
        SDL_UploadToGPUTexture(copy_pass, *info, *region, false);
        cursor += size;
    }
    
    SDL_EndGPUCopyPass(copy_pass);
    
    for textures {
        SDL_GenerateMipmapsForGPUTexture(command_buffer, it.gpu_texture);
    }
    
    SDL_SubmitGPUCommandBuffer(command_buffer);
    SDL_ReleaseGPUTransferBuffer(gpu_device, transfer_buffer);
    
    for textures {
        stb_image_free(it.pixels);
        it.pixels = null;
    }
}

load_texture :: (path: string) -> *Texture {
    for textures {
        if equal(it.path, path) return it;
    }
    
    width, height, channels: s32;
    pixels := stb_load_image(path.data, *width, *height, *channels, 4);
    if !pixels return *null_texture;
    
    texture := arena_push(*textures);
    texture.path = path;
    texture.width = xx width;
    texture.height = xx height;
    texture.pixels = pixels;
    texture.format = .RGBA;
    texture.pixel_size = 4;
    
    return texture;
}

create_texture :: (name: string, width: int, height: int, pixels: *u8, format: Texture_Format = .RGBA) -> *Texture {
    assert(false);
    
    texture := arena_push(*textures);
    texture.path = name;
    texture.width = width;
    texture.height = height;
    texture.format = format;
    if #complete format == {
        case .RGBA; texture.pixel_size = 4;
        case .RGB; texture.pixel_size = 3;
        case .R; texture.pixel_size = 1;
    }
    return texture;
}

#scope_file

textures: Typed_Arena(Texture);

null_texture := Texture.{};

#import "Basic";
#import "String";