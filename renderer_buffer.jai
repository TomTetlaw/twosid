
CreateVertexBuffer :: (Name: string, Stride: int, Elements: int) -> *SDL_GPUBuffer {
    VertexCreateInfo: SDL_GPUBufferCreateInfo;
    VertexCreateInfo.usage = SDL_GPU_BUFFERUSAGE_VERTEX;
    VertexCreateInfo.size = xx (Stride * Elements);
    Buffer := SDL_CreateGPUBuffer(GDevice, *VertexCreateInfo);
    SDL_SetGPUBufferName(GDevice, Buffer, Name.data);
    return Buffer;
}

CreateIndexBuffer :: (Name: string, Elements: int) -> *SDL_GPUBuffer {
    IndexCreateInfo: SDL_GPUBufferCreateInfo;
    IndexCreateInfo.usage = SDL_GPU_BUFFERUSAGE_INDEX;
    IndexCreateInfo.size = xx (Elements * size_of(u32));
    Buffer := SDL_CreateGPUBuffer(GDevice, *IndexCreateInfo);
    SDL_SetGPUBufferName(GDevice, Buffer, Name.data);
    return Buffer;
}

CreateBuffer :: (Name: string, Size: int, Usage: SDL_GPUBufferUsageFlags) -> *SDL_GPUBuffer {
    CreateInfo: SDL_GPUBufferCreateInfo;
    CreateInfo.usage = Usage;
    CreateInfo.size = xx Size;
    Buffer := SDL_CreateGPUBuffer(GDevice, *CreateInfo);
    SDL_SetGPUBufferName(GDevice, Buffer, Name.data);
    return Buffer;
}

CreateTransferBuffer :: (Size: int) -> *SDL_GPUTransferBuffer {
    TransferCreateInfo: SDL_GPUTransferBufferCreateInfo;
    TransferCreateInfo.usage = .SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD;
    TransferCreateInfo.size = xx Size;
    return SDL_CreateGPUTransferBuffer(GDevice, *TransferCreateInfo);
}

CreateVertexBuffer :: (Name: string, Elements: [] $T, Index := false) -> *SDL_GPUBuffer {
    Buffer: *SDL_GPUBuffer;
    
    if Index Buffer = CreateIndexBuffer(Name, Elements.count);
    else Buffer = CreateVertexBuffer(Name, size_of(T), Elements.count);
    
    TransferBuffer := CreateTransferBuffer(Elements.count * size_of(T));
    
    TransferMemory := SDL_MapGPUTransferBuffer(GDevice, TransferBuffer, false);
    Copy(TransferMemory, Elements.data, size_of(T) * Elements.count);
    SDL_UnmapGPUTransferBuffer(GDevice, TransferBuffer);
    
    Location: SDL_GPUTransferBufferLocation;
    Location.transfer_buffer = TransferBuffer;
    Location.offset = 0;
    
    Region: SDL_GPUBufferRegion;
    Region.offset = 0;
    Region.buffer = Buffer;
    Region.size = xx (size_of(T) * Elements.count);
    
    CommandBuffer := SDL_AcquireGPUCommandBuffer(GDevice);
    CopyPass := SDL_BeginGPUCopyPass(CommandBuffer);
    
    SDL_UploadToGPUBuffer(CopyPass, *Location, *Region, false);
    
    SDL_EndGPUCopyPass(CopyPass);
    SDL_SubmitGPUCommandBuffer(CommandBuffer);
    SDL_ReleaseGPUTransferBuffer(GDevice, TransferBuffer);
    
    return Buffer;
}